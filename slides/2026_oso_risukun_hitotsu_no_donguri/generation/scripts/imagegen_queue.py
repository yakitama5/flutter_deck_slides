#!/usr/bin/env python3
"""Manage a subscription-only queue for Codex's built-in ImageGen tool.

The built-in ImageGen tool is available to Codex itself, not to a local Python
process.  This module therefore keeps the durable part of the workflow local:
prompts, reference roles, attempt numbers, output paths, review state, and
human-approved adoption.  A Codex worker can process the generated job files
one at a time with the built-in tool and record each resulting PNG here.

This script never imports the OpenAI SDK and never requires OPENAI_API_KEY.
"""

from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import os
import shutil
import sys
import tempfile
import textwrap
from pathlib import Path
from typing import Any, Mapping, Sequence


SCRIPT_PATH = Path(__file__).resolve()
SCRIPT_DIR = SCRIPT_PATH.parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

import generate_storybook as storybook  # noqa: E402


DEFAULT_STORYBOOK_DIR = SCRIPT_PATH.parents[2]
QUEUE_FILENAME = ".imagegen_queue.json"
JOBS_DIRNAME = "jobs"
WORKER_FILENAME = "BUILTIN_IMAGEGEN_WORKER.md"
QUEUE_SCHEMA_VERSION = 1
DEFAULT_MAX_RETRIES = 2
JOB_PENDING = "pending"
JOB_READY = "ready_for_review"
JOB_ADOPTED = "adopted"
JOB_FAILED = "failed"
JOB_REVISION_REQUESTED = "revision_requested"
JOB_SUPERSEDED = "superseded"
REVIEWABLE_JOB_STATUSES = {JOB_READY, JOB_ADOPTED}


class QueueError(RuntimeError):
    """A user-actionable queue configuration or state error."""


def now_iso() -> str:
    return dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds")


def queue_path(storybook_dir: Path) -> Path:
    return storybook_dir / "generation" / "output" / QUEUE_FILENAME


def jobs_dir(storybook_dir: Path) -> Path:
    return storybook_dir / "generation" / "output" / JOBS_DIRNAME


def relative_path(path: Path, storybook_dir: Path) -> str:
    return str(path.resolve().relative_to(storybook_dir.resolve()))


def absolute_path(relative: str, storybook_dir: Path) -> Path:
    return (storybook_dir / relative).resolve()


def atomic_write_json(path: Path, payload: Mapping[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary_name = tempfile.mkstemp(
        prefix=f".{path.name}.", suffix=".tmp", dir=str(path.parent)
    )
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as handle:
            json.dump(payload, handle, ensure_ascii=False, indent=2)
            handle.write("\n")
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temporary_name, path)
    except Exception:
        try:
            os.unlink(temporary_name)
        except FileNotFoundError:
            pass
        raise


def atomic_write_text(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary_name = tempfile.mkstemp(
        prefix=f".{path.name}.", suffix=".tmp", dir=str(path.parent)
    )
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as handle:
            handle.write(content)
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temporary_name, path)
    except Exception:
        try:
            os.unlink(temporary_name)
        except FileNotFoundError:
            pass
        raise


def atomic_copy(source: Path, destination: Path) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    temporary = destination.with_suffix(destination.suffix + ".tmp")
    try:
        shutil.copyfile(source, temporary)
        os.replace(temporary, destination)
    except Exception:
        try:
            temporary.unlink()
        except FileNotFoundError:
            pass
        raise


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def context_for(storybook_dir: Path, quality: str = "medium") -> storybook.RunContext:
    return storybook.RunContext(
        storybook_dir=storybook_dir,
        dry_run=True,
        quality=quality,
        max_retries=DEFAULT_MAX_RETRIES,
        regenerate=False,
        regenerate_locked=False,
        resume=True,
    )


def initial_queue(pages: Sequence[storybook.PageSpec], max_retries: int) -> dict[str, Any]:
    return {
        "schema_version": QUEUE_SCHEMA_VERSION,
        "mode": "codex_builtin_imagegen",
        "storybook": "risukun_hitotsu_no_donguri",
        "image_model": storybook.IMAGE_MODEL,
        "max_retries": max_retries,
        "max_attempts": max_retries + 1,
        "created_at": now_iso(),
        "updated_at": now_iso(),
        "pages": {
            page.id: {
                "status": "pending",
                "locked": page.locked,
                "jobs": [],
            }
            for page in pages
        },
        "jobs": [],
    }


def load_queue(
    storybook_dir: Path,
    pages: Sequence[storybook.PageSpec],
    max_retries: int | None = None,
) -> dict[str, Any]:
    path = queue_path(storybook_dir)
    if not path.is_file():
        retries = DEFAULT_MAX_RETRIES if max_retries is None else max_retries
        if retries < 0:
            raise QueueError("--max-retries must be zero or greater")
        return initial_queue(pages, retries)
    try:
        loaded = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise QueueError(f"Could not read queue file {path}: {exc}") from exc
    if not isinstance(loaded, Mapping):
        raise QueueError(f"Queue file {path} must contain a JSON object")
    queue = dict(loaded)
    if queue.get("schema_version") != QUEUE_SCHEMA_VERSION:
        raise QueueError(
            f"Unsupported queue schema {queue.get('schema_version')!r}; expected {QUEUE_SCHEMA_VERSION}"
        )
    if not isinstance(queue.get("jobs"), list):
        raise QueueError(f"Queue file {path} must contain a jobs list")
    existing_retries = int(queue.get("max_retries", DEFAULT_MAX_RETRIES))
    if max_retries is not None and max_retries != existing_retries and queue["jobs"]:
        raise QueueError(
            f"Queue already uses max_retries={existing_retries}; keep it or remove the local queue before changing it"
        )
    queue["max_retries"] = existing_retries if max_retries is None else max_retries
    queue["max_attempts"] = queue["max_retries"] + 1
    raw_pages = queue.setdefault("pages", {})
    if not isinstance(raw_pages, Mapping):
        raise QueueError(f"Queue file {path} must contain a pages object")
    normalized_pages = dict(raw_pages)
    for page in pages:
        current = normalized_pages.get(page.id, {})
        if not isinstance(current, Mapping):
            current = {}
        normalized_pages[page.id] = {
            "status": current.get("status", "pending"),
            "locked": page.locked,
            "jobs": list(current.get("jobs", []))
            if isinstance(current.get("jobs", []), list)
            else [],
        }
    queue["pages"] = normalized_pages
    return queue


def save_queue(storybook_dir: Path, queue: dict[str, Any]) -> None:
    queue["updated_at"] = now_iso()
    atomic_write_json(queue_path(storybook_dir), queue)


def page_by_id(pages: Sequence[storybook.PageSpec], page_id: str) -> storybook.PageSpec:
    for page in pages:
        if page.id == page_id:
            return page
    raise QueueError(f"Unknown page {page_id!r}; choose from {', '.join(page.id for page in pages)}")


def job_id(page_id: str, variant_id: str, attempt: int) -> str:
    return f"{page_id}__variant_{variant_id}__attempt_{attempt:02d}"


def jobs_for(
    queue: Mapping[str, Any], page_id: str, variant_id: str | None = None
) -> list[dict[str, Any]]:
    result = []
    raw_jobs = queue.get("jobs", [])
    if not isinstance(raw_jobs, list):
        return result
    for raw_job in raw_jobs:
        if not isinstance(raw_job, Mapping) or raw_job.get("page") != page_id:
            continue
        if variant_id is not None and raw_job.get("variant") != variant_id:
            continue
        result.append(dict(raw_job))
    return sorted(result, key=lambda item: int(item.get("attempt", 0)))


def latest_job(
    queue: Mapping[str, Any], page_id: str, variant_id: str
) -> dict[str, Any] | None:
    matches = jobs_for(queue, page_id, variant_id)
    return matches[-1] if matches else None


def replace_job(queue: dict[str, Any], replacement: Mapping[str, Any]) -> None:
    jobs = queue.setdefault("jobs", [])
    job_identifier = replacement.get("id")
    for index, raw_job in enumerate(jobs):
        if isinstance(raw_job, Mapping) and raw_job.get("id") == job_identifier:
            jobs[index] = dict(replacement)
            return
    jobs.append(dict(replacement))


def page_latest_jobs(
    queue: Mapping[str, Any], page_id: str
) -> dict[str, dict[str, Any]]:
    latest: dict[str, dict[str, Any]] = {}
    for variant_id in storybook.VARIANTS:
        job = latest_job(queue, page_id, variant_id)
        if job is not None:
            latest[variant_id] = job
    return latest


def refresh_page_status(
    storybook_dir: Path, queue: dict[str, Any], page_id: str
) -> str:
    latest = page_latest_jobs(queue, page_id)
    page_entry = queue.setdefault("pages", {}).setdefault(page_id, {})
    if not latest:
        status = "pending"
    elif all(
        job.get("status") in REVIEWABLE_JOB_STATUSES
        and absolute_path(str(job.get("candidate_output", "")), storybook_dir).is_file()
        for job in latest.values()
    ) and len(latest) == len(storybook.VARIANTS):
        status = "ready_for_review"
    elif any(job.get("status") == JOB_FAILED for job in latest.values()):
        status = "failed"
    else:
        status = "generating"
    page_entry["status"] = status
    page_entry["jobs"] = [job["id"] for job in latest.values()]
    page_entry["updated_at"] = now_iso()
    return status


def refresh_all_page_statuses(
    storybook_dir: Path, queue: dict[str, Any], pages: Sequence[storybook.PageSpec]
) -> None:
    for page in pages:
        refresh_page_status(storybook_dir, queue, page.id)


def build_job(
    storybook_dir: Path,
    pages: Sequence[storybook.PageSpec],
    page: storybook.PageSpec,
    variant_id: str,
    style: str,
    attempt: int,
    quality: str,
    revision_instruction: str | None = None,
) -> dict[str, Any]:
    if variant_id not in storybook.VARIANTS:
        raise QueueError(f"Variant must be one of {', '.join(storybook.VARIANTS)}")
    context = context_for(storybook_dir, quality)
    references = storybook.select_references(context, page, pages)
    variant = page.variants[variant_id]
    prompt = storybook.build_prompt(
        page,
        variant,
        style,
        references,
        revision_instruction=revision_instruction,
    )
    output_page_dir = storybook_dir / "generation" / "output" / page.id
    candidate_output = output_page_dir / f"variant_{variant_id}.png"
    attempt_output = output_page_dir / "attempts" / f"variant_{variant_id}_attempt_{attempt:02d}.png"
    job_file = jobs_dir(storybook_dir) / f"{page.id}__variant_{variant_id}__attempt_{attempt:02d}.md"
    return {
        "id": job_id(page.id, variant_id, attempt),
        "page": page.id,
        "variant": variant_id,
        "attempt": attempt,
        "status": JOB_PENDING,
        "quality_target": quality,
        "prompt": prompt,
        "prompt_sha256": storybook.prompt_hash(prompt),
        "revision_instruction": revision_instruction,
        "references": [
            {
                "path": relative_path(reference.path, storybook_dir),
                "role": reference.role,
            }
            for reference in references
        ],
        "candidate_output": relative_path(candidate_output, storybook_dir),
        "attempt_output": relative_path(attempt_output, storybook_dir),
        "job_file": relative_path(job_file, storybook_dir),
        "created_at": now_iso(),
        "updated_at": now_iso(),
    }


def job_markdown(storybook_dir: Path, job: Mapping[str, Any]) -> str:
    references = job.get("references", [])
    reference_lines: list[str] = []
    if isinstance(references, list):
        for index, raw_reference in enumerate(references, start=1):
            if not isinstance(raw_reference, Mapping):
                continue
            path = absolute_path(str(raw_reference.get("path", "")), storybook_dir)
            role = str(raw_reference.get("role", "reference"))
            reference_lines.append(f"{index}. `{path}` — {role}")
    if not reference_lines:
        reference_lines.append("(no local reference image; follow the written canonical style)")
    revision = job.get("revision_instruction")
    revision_block = (
        "\n## Human review revision\n\n" + str(revision).strip() + "\n"
        if revision
        else ""
    )
    record_command = (
        "python3 generation/scripts/imagegen_queue.py record "
        f"--job-id {job['id']} --source \"<path returned by built-in ImageGen>\""
    )
    return textwrap.dedent(
        f"""\
        # Codex built-in ImageGen job: {job['page']}/{job['variant']} attempt {int(job['attempt']):02d}

        Status: `{job['status']}`
        Use case: `illustration-story`
        Mode: Codex built-in ImageGen only — do not use the OpenAI SDK or `OPENAI_API_KEY`.
        Canvas intent: wide 16:9 picture-book illustration for the project's 2048x1152 layout.

        ## Reference images

        {chr(10).join(reference_lines)}

        Use each attached image only for the role stated above. Preserve character identity,
        palette, and visual language; do not copy a reference image's framing or composition.

        ## Prompt

        Include `$imagegen` when invoking the built-in image generation skill, then use this
        prompt verbatim:

        ```text
        {job['prompt']}
        ```
        {revision_block}
        ## Record the result

        Generate exactly this one candidate. After the tool finishes, copy or move the saved
        PNG into the workspace by running:

        ```sh
        {record_command}
        ```

        The recorder stores the attempt permanently, updates `variant_{job['variant']}.png`
        as the current review candidate, and creates a review manifest when all three variants
        for the page are present. Do not adopt a final asset during the background generation
        pass.

        Candidate path: `{storybook_dir / str(job['candidate_output'])}`
        Attempt archive path: `{storybook_dir / str(job['attempt_output'])}`
        """
    )


def write_job_file(storybook_dir: Path, job: Mapping[str, Any]) -> None:
    atomic_write_text(
        storybook_dir / str(job["job_file"]),
        job_markdown(storybook_dir, job),
    )


def write_worker_instructions(
    storybook_dir: Path, queue: Mapping[str, Any], pages: Sequence[storybook.PageSpec]
) -> None:
    open_pages = [page.id for page in pages if not page.locked]
    worker_path = storybook_dir / "generation" / "output" / WORKER_FILENAME
    content = textwrap.dedent(
        f"""\
        # Background worker: Codex built-in ImageGen

        This is a local runbook for a Codex task operating in the same workspace. The queue is
        subscription-only: use the built-in `image_gen` tool and never call the OpenAI SDK or
        set `OPENAI_API_KEY`.

        The target is one page at a time, in this order: {", ".join(open_pages)}.
        Keep every `a`, `b`, and `c` candidate. Do not run the human adoption step.

        ## Worker loop

        1. Prepare the next page. This refreshes continuity references after the previous page
           has finished:

           ```sh
           python3 generation/scripts/imagegen_queue.py prepare --next-page
           ```

        2. Inspect the next pending job:

           ```sh
           python3 generation/scripts/imagegen_queue.py next
           ```

        3. Read the printed `.md` job file. Call the built-in ImageGen tool once using all listed
           reference images and the job's prompt. Do not use an API key or the API fallback.

        4. Record the saved PNG with the command in the job file. Repeat steps 2–4 until the
           current page has all three variants.

        5. Generate the contact sheet when possible, then return to step 1. Stop only when
           `status` reports every unlocked page as `ready_for_review`, or when a quota/tool
           failure makes further progress impossible. Leave pending jobs intact on failure.

        Useful commands:

        ```sh
        python3 generation/scripts/imagegen_queue.py status
        python3 generation/scripts/imagegen_queue.py review
        python3 generation/scripts/make_contact_sheet.py --page page05
        ```

        Queue file: `{queue_path(storybook_dir)}`
        Worker file: `{worker_path}`
        Max attempts per candidate: `{queue.get("max_attempts", "?")}`
        """
    )
    atomic_write_text(worker_path, content)


def selected_pages(
    storybook_dir: Path,
    pages: Sequence[storybook.PageSpec],
    page_id: str | None,
    from_page: str | None,
    to_page: str | None,
) -> tuple[storybook.PageSpec, ...]:
    return storybook.selected_pages(
        pages,
        page_id=page_id,
        from_page=from_page,
        to_page=to_page,
    )


def prepare_page(
    storybook_dir: Path,
    queue: dict[str, Any],
    pages: Sequence[storybook.PageSpec],
    page: storybook.PageSpec,
    style: str,
    variant_id: str | None,
    quality: str,
    regenerate_locked: bool,
    print_prompts: bool,
) -> list[dict[str, Any]]:
    if page.locked and not regenerate_locked:
        print(f"SKIP locked {page.id} (use --regenerate-locked to include it)")
        return []
    variants = [variant_id] if variant_id else list(storybook.VARIANTS)
    prepared: list[dict[str, Any]] = []
    for current_variant in variants:
        latest = latest_job(queue, page.id, current_variant)
        if latest is not None and latest.get("status") in REVIEWABLE_JOB_STATUSES:
            candidate = absolute_path(str(latest.get("candidate_output", "")), storybook_dir)
            if candidate.is_file():
                print(f"EXISTS {page.id}/{current_variant}: {latest['id']}")
                prepared.append(latest)
                continue
        if latest is not None and latest.get("status") == JOB_PENDING:
            refreshed = build_job(
                storybook_dir,
                pages,
                page,
                current_variant,
                style,
                int(latest.get("attempt", 1)),
                quality,
                latest.get("revision_instruction"),
            )
            refreshed["id"] = latest["id"]
            refreshed["created_at"] = latest.get("created_at", refreshed["created_at"])
            replace_job(queue, refreshed)
            write_job_file(storybook_dir, refreshed)
            print(f"REFRESHED {page.id}/{current_variant}: {refreshed['job_file']}")
            prepared.append(refreshed)
            if print_prompts:
                print(refreshed["prompt"])
            continue
        attempt = int(latest.get("attempt", 0)) + 1 if latest else 1
        job = build_job(
            storybook_dir,
            pages,
            page,
            current_variant,
            style,
            attempt,
            quality,
            latest.get("revision_instruction") if latest else None,
        )
        replace_job(queue, job)
        write_job_file(storybook_dir, job)
        prepared.append(job)
        print(f"PREPARED {page.id}/{current_variant}: {job['job_file']}")
        if print_prompts:
            print(job["prompt"])
    refresh_page_status(storybook_dir, queue, page.id)
    return prepared


def next_page_to_prepare(
    storybook_dir: Path,
    queue: Mapping[str, Any],
    pages: Sequence[storybook.PageSpec],
) -> storybook.PageSpec | None:
    for page in pages:
        if page.locked:
            continue
        latest = page_latest_jobs(queue, page.id)
        if len(latest) < len(storybook.VARIANTS):
            return page
        if any(job.get("status") not in REVIEWABLE_JOB_STATUSES for job in latest.values()):
            return page
        if any(
            not absolute_path(str(job.get("candidate_output", "")), storybook_dir).is_file()
            for job in latest.values()
        ):
            return page
    return None


def review_manifest(
    storybook_dir: Path,
    queue: dict[str, Any],
    page: storybook.PageSpec,
) -> Path | None:
    latest = page_latest_jobs(queue, page.id)
    if len(latest) != len(storybook.VARIANTS):
        return None
    page_dir = storybook_dir / "generation" / "output" / page.id
    payload = {
        "schema_version": 1,
        "mode": "codex_builtin_imagegen",
        "page": page.id,
        "generated_at": now_iso(),
        "human_decision_required": True,
        "status": queue.get("pages", {}).get(page.id, {}).get("status"),
        "variants": {
            variant_id: {
                "job_id": job["id"],
                "attempt": job.get("attempt"),
                "status": job.get("status"),
                "prompt_sha256": job.get("prompt_sha256"),
                "candidate_output": job.get("candidate_output"),
                "attempt_output": job.get("attempt_output"),
                "image_sha256": job.get("image_sha256"),
            }
            for variant_id, job in latest.items()
        },
        "contact_sheet": str(page_dir / "contact_sheet.png")
        if (page_dir / "contact_sheet.png").is_file()
        else None,
    }
    path = page_dir / "builtin_review.json"
    atomic_write_json(path, payload)
    return path


def maybe_make_contact_sheet(storybook_dir: Path, page_id: str) -> str | None:
    try:
        from make_contact_sheet import make_contact_sheet  # type: ignore
    except ImportError:
        return "Pillow is not installed; install generation/requirements.txt to create contact_sheet.png"
    page_dir = storybook_dir / "generation" / "output" / page_id
    try:
        make_contact_sheet(page_dir)
    except Exception as exc:
        return str(exc)
    return None


def record_job(
    storybook_dir: Path,
    queue: dict[str, Any],
    pages: Sequence[storybook.PageSpec],
    job_identifier: str,
    source: Path,
    force: bool,
) -> dict[str, Any]:
    raw_jobs = queue.get("jobs", [])
    job: dict[str, Any] | None = None
    for raw_job in raw_jobs:
        if isinstance(raw_job, Mapping) and raw_job.get("id") == job_identifier:
            job = dict(raw_job)
            break
    if job is None:
        raise QueueError(f"Unknown job {job_identifier!r}; run the prepare command first")
    if job.get("status") in REVIEWABLE_JOB_STATUSES and not force:
        raise QueueError(f"Job {job_identifier} is already recorded; use --force to replace it")
    source = source.expanduser().resolve()
    if not source.is_file():
        raise QueueError(f"Image source does not exist: {source}")
    attempt_path = absolute_path(str(job["attempt_output"]), storybook_dir)
    candidate_path = absolute_path(str(job["candidate_output"]), storybook_dir)
    atomic_copy(source, attempt_path)
    atomic_copy(source, candidate_path)

    for other in raw_jobs:
        if not isinstance(other, Mapping) or other.get("id") == job_identifier:
            continue
        if (
            other.get("page") == job.get("page")
            and other.get("variant") == job.get("variant")
            and other.get("status") in REVIEWABLE_JOB_STATUSES
        ):
            other["status"] = JOB_SUPERSEDED
            other["updated_at"] = now_iso()
    job.update(
        {
            "status": JOB_READY,
            "source": str(source),
            "image_sha256": sha256_file(candidate_path),
            "recorded_at": now_iso(),
            "updated_at": now_iso(),
        }
    )
    replace_job(queue, job)
    page = page_by_id(pages, str(job["page"]))
    refresh_page_status(storybook_dir, queue, page.id)
    if queue["pages"][page.id]["status"] == "ready_for_review":
        warning = maybe_make_contact_sheet(storybook_dir, page.id)
        page_entry = queue["pages"][page.id]
        if warning:
            page_entry["contact_sheet_warning"] = warning
        else:
            page_entry.pop("contact_sheet_warning", None)
        review_manifest(storybook_dir, queue, page)
    save_queue(storybook_dir, queue)
    write_job_file(storybook_dir, job)
    return job


def revise_job(
    storybook_dir: Path,
    queue: dict[str, Any],
    pages: Sequence[storybook.PageSpec],
    style: str,
    page_id: str,
    variant_id: str,
    note: str,
    quality: str,
) -> dict[str, Any]:
    if not note.strip():
        raise QueueError("--note must not be empty")
    page = page_by_id(pages, page_id)
    latest = latest_job(queue, page_id, variant_id)
    if latest is None:
        raise QueueError(f"No existing candidate for {page_id}/{variant_id}")
    if not absolute_path(str(latest.get("candidate_output", "")), storybook_dir).is_file():
        raise QueueError(f"Candidate image is missing for {page_id}/{variant_id}")
    attempt = int(latest.get("attempt", 0)) + 1
    if attempt > int(queue.get("max_attempts", DEFAULT_MAX_RETRIES + 1)):
        raise QueueError(
            f"{page_id}/{variant_id} reached max attempts ({queue.get('max_attempts')}); start a new queue to exceed it"
        )
    job = build_job(
        storybook_dir,
        pages,
        page,
        variant_id,
        style,
        attempt,
        quality,
        revision_instruction=note.strip(),
    )
    replace_job(queue, job)
    page_entry = queue["pages"][page_id]
    page_entry["status"] = "generating"
    page_entry["revision_requested_at"] = now_iso()
    write_job_file(storybook_dir, job)
    save_queue(storybook_dir, queue)
    return job


def adopt_job(
    storybook_dir: Path,
    queue: dict[str, Any],
    pages: Sequence[storybook.PageSpec],
    page_id: str,
    variant_id: str,
    force: bool,
) -> Path:
    page = page_by_id(pages, page_id)
    latest = latest_job(queue, page_id, variant_id)
    if latest is None:
        raise QueueError(f"No existing candidate for {page_id}/{variant_id}")
    source = absolute_path(str(latest.get("candidate_output", "")), storybook_dir)
    if not source.is_file():
        raise QueueError(f"Candidate image is missing: {source}")
    target = storybook_dir / "assets" / "risukun_hitotsu_no_donguri" / f"{page.id}.png"
    if target.exists() and not force:
        raise QueueError(f"{target} already exists; use --force to replace it")
    atomic_copy(source, target)
    latest["status"] = JOB_ADOPTED
    latest["adopted_at"] = now_iso()
    latest["adopted_output"] = relative_path(target, storybook_dir)
    replace_job(queue, latest)
    page_entry = queue["pages"][page_id]
    page_entry["status"] = "adopted"
    page_entry["selected_variant"] = variant_id
    page_entry["adopted_at"] = now_iso()
    save_queue(storybook_dir, queue)
    return target


def print_status(
    storybook_dir: Path,
    queue: Mapping[str, Any],
    pages: Sequence[storybook.PageSpec],
    as_json: bool,
) -> None:
    if as_json:
        print(json.dumps(queue, ensure_ascii=False, indent=2))
        return
    print(f"QUEUE {queue_path(storybook_dir)}")
    print(
        f"mode={queue.get('mode')} max_attempts={queue.get('max_attempts')} "
        "(subscription-only; built-in ImageGen)"
    )
    jobs = queue.get("jobs", [])
    pending = sum(
        isinstance(job, Mapping) and job.get("status") == JOB_PENDING for job in jobs
    )
    print(f"pending_jobs={pending}")
    for page in pages:
        entry = queue.get("pages", {}).get(page.id, {})
        latest = page_latest_jobs(queue, page.id)
        variants = ", ".join(
            f"{variant}={latest[variant].get('status')}"
            for variant in storybook.VARIANTS
            if variant in latest
        )
        lock = " locked" if page.locked else ""
        print(f"{page.id}{lock}: {entry.get('status', 'pending')} [{variants or 'no jobs'}]")


def print_next(queue: Mapping[str, Any], as_json: bool) -> None:
    jobs = [
        dict(job)
        for job in queue.get("jobs", [])
        if isinstance(job, Mapping) and job.get("status") == JOB_PENDING
    ]
    jobs.sort(
        key=lambda job: (
            storybook.PAGE_ORDER.index(str(job.get("page")))
            if job.get("page") in storybook.PAGE_ORDER
            else len(storybook.PAGE_ORDER),
            str(job.get("variant")),
            int(job.get("attempt", 0)),
        )
    )
    if not jobs:
        print("NO_PENDING_JOBS")
        return
    job = jobs[0]
    if as_json:
        print(json.dumps(job, ensure_ascii=False, indent=2))
        return
    print(f"NEXT {job['page']}/{job['variant']} attempt {int(job['attempt']):02d}")
    print(job["job_file"])
    print(f"prompt_sha256={job['prompt_sha256']}")


def print_review(
    storybook_dir: Path,
    queue: Mapping[str, Any],
    pages: Sequence[storybook.PageSpec],
    page_id: str | None,
) -> None:
    selected = [page_by_id(pages, page_id)] if page_id else list(pages)
    found = False
    for page in selected:
        if queue.get("pages", {}).get(page.id, {}).get("status") != "ready_for_review":
            continue
        found = True
        page_dir = storybook_dir / "generation" / "output" / page.id
        print(f"REVIEW {page.id}")
        print(f"  contact_sheet: {page_dir / 'contact_sheet.png'}")
        print(f"  manifest:       {page_dir / 'builtin_review.json'}")
        for variant_id in storybook.VARIANTS:
            print(f"  variant_{variant_id}:  {page_dir / f'variant_{variant_id}.png'}")
    if not found:
        print("NO_PAGES_READY_FOR_REVIEW")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--storybook-dir",
        type=Path,
        default=DEFAULT_STORYBOOK_DIR,
        help="Storybook directory (defaults to this Issue #28 storybook)",
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    prepare = subparsers.add_parser("prepare", help="Create or refresh local ImageGen jobs")
    prepare.add_argument("--page")
    prepare.add_argument("--from-page")
    prepare.add_argument("--to-page")
    prepare.add_argument("--next-page", action="store_true")
    prepare.add_argument("--variant", choices=storybook.VARIANTS)
    prepare.add_argument("--quality", choices=("low", "medium", "high"), default="medium")
    prepare.add_argument("--max-retries", type=int, default=None)
    prepare.add_argument("--regenerate-locked", action="store_true")
    prepare.add_argument("--print-prompts", action="store_true")
    prepare.add_argument("--storybook-dir", type=Path, default=argparse.SUPPRESS)

    for name in ("status", "next"):
        status_parser = subparsers.add_parser(name, help=f"Show the queue {name}")
        status_parser.add_argument("--json", action="store_true")
        status_parser.add_argument("--storybook-dir", type=Path, default=argparse.SUPPRESS)

    review = subparsers.add_parser("review", help="List completed pages awaiting human review")
    review.add_argument("--page")
    review.add_argument("--storybook-dir", type=Path, default=argparse.SUPPRESS)

    record = subparsers.add_parser("record", help="Record a PNG produced by built-in ImageGen")
    record.add_argument("--job-id", required=True)
    record.add_argument("--source", type=Path, required=True)
    record.add_argument("--force", action="store_true")
    record.add_argument("--storybook-dir", type=Path, default=argparse.SUPPRESS)

    revise = subparsers.add_parser("revise", help="Queue a human-directed revision")
    revise.add_argument("--page", required=True)
    revise.add_argument("--variant", choices=storybook.VARIANTS, required=True)
    revise.add_argument("--note", required=True)
    revise.add_argument("--quality", choices=("low", "medium", "high"), default="medium")
    revise.add_argument("--storybook-dir", type=Path, default=argparse.SUPPRESS)

    fail = subparsers.add_parser("fail", help="Leave a job retryable after a tool failure")
    fail.add_argument("--job-id", required=True)
    fail.add_argument("--message", required=True)
    fail.add_argument("--storybook-dir", type=Path, default=argparse.SUPPRESS)

    retry = subparsers.add_parser("retry", help="Re-open a failed job")
    retry.add_argument("--job-id", required=True)
    retry.add_argument("--storybook-dir", type=Path, default=argparse.SUPPRESS)

    adopt = subparsers.add_parser("adopt", help="Copy a reviewed candidate into final assets")
    adopt.add_argument("--page", required=True)
    adopt.add_argument("--variant", choices=storybook.VARIANTS, required=True)
    adopt.add_argument("--force", action="store_true")
    adopt.add_argument("--storybook-dir", type=Path, default=argparse.SUPPRESS)
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    storybook_dir = args.storybook_dir.resolve()
    try:
        storyboard_path = storybook_dir / "generation" / "prompts" / "storyboard.yaml"
        style_path = storybook_dir / "generation" / "prompts" / "global_style.md"
        pages = storybook.load_storyboard(storyboard_path)
        style = storybook.load_style(style_path)

        if args.command == "prepare":
            if args.max_retries is not None and args.max_retries < 0:
                raise QueueError("--max-retries must be zero or greater")
            if args.next_page and (args.page or args.from_page or args.to_page):
                raise QueueError("--next-page cannot be combined with --page or a page range")
            queue = load_queue(storybook_dir, pages, args.max_retries)
            if args.next_page:
                page = next_page_to_prepare(storybook_dir, queue, pages)
                if page is None:
                    refresh_all_page_statuses(storybook_dir, queue, pages)
                    save_queue(storybook_dir, queue)
                    print("ALL_UNLOCKED_PAGES_READY")
                    write_worker_instructions(storybook_dir, queue, pages)
                    return 0
                chosen_pages = (page,)
            else:
                chosen_pages = selected_pages(
                    storybook_dir, pages, args.page, args.from_page, args.to_page
                )
            for page in chosen_pages:
                prepare_page(
                    storybook_dir,
                    queue,
                    pages,
                    page,
                    style,
                    args.variant,
                    args.quality,
                    args.regenerate_locked,
                    args.print_prompts,
                )
            refresh_all_page_statuses(storybook_dir, queue, pages)
            save_queue(storybook_dir, queue)
            write_worker_instructions(storybook_dir, queue, pages)
            return 0

        queue = load_queue(storybook_dir, pages)
        refresh_all_page_statuses(storybook_dir, queue, pages)

        if args.command == "status":
            print_status(storybook_dir, queue, pages, args.json)
            return 0
        if args.command == "next":
            print_next(queue, args.json)
            return 0
        if args.command == "review":
            print_review(storybook_dir, queue, pages, args.page)
            return 0
        if args.command == "record":
            job = record_job(
                storybook_dir,
                queue,
                pages,
                args.job_id,
                args.source,
                args.force,
            )
            print(
                f"RECORDED {job['page']}/{job['variant']} attempt {int(job['attempt']):02d} "
                f"-> {storybook_dir / str(job['candidate_output'])}"
            )
            return 0
        if args.command == "revise":
            job = revise_job(
                storybook_dir,
                queue,
                pages,
                style,
                args.page,
                args.variant,
                args.note,
                args.quality,
            )
            print(f"REVISION_QUEUED {job['page']}/{job['variant']}: {job['job_file']}")
            return 0
        if args.command == "fail":
            job = None
            for raw_job in queue.get("jobs", []):
                if isinstance(raw_job, Mapping) and raw_job.get("id") == args.job_id:
                    job = dict(raw_job)
                    break
            if job is None:
                raise QueueError(f"Unknown job {args.job_id!r}")
            job.update({"status": JOB_FAILED, "error": args.message, "failed_at": now_iso()})
            replace_job(queue, job)
            refresh_page_status(storybook_dir, queue, str(job["page"]))
            save_queue(storybook_dir, queue)
            print(f"FAILED {args.job_id}: {args.message}")
            return 0
        if args.command == "retry":
            job = None
            for raw_job in queue.get("jobs", []):
                if isinstance(raw_job, Mapping) and raw_job.get("id") == args.job_id:
                    job = dict(raw_job)
                    break
            if job is None:
                raise QueueError(f"Unknown job {args.job_id!r}")
            if job.get("status") != JOB_FAILED:
                raise QueueError(f"Job {args.job_id} is not failed")
            job.update({"status": JOB_PENDING, "error": None, "retried_at": now_iso()})
            replace_job(queue, job)
            refresh_page_status(storybook_dir, queue, str(job["page"]))
            write_job_file(storybook_dir, job)
            save_queue(storybook_dir, queue)
            print(f"RETRY_READY {args.job_id}")
            return 0
        if args.command == "adopt":
            target = adopt_job(
                storybook_dir,
                queue,
                pages,
                args.page,
                args.variant,
                args.force,
            )
            print(f"ADOPTED {args.page}/{args.variant} -> {target}")
            return 0
        raise QueueError(f"Unknown command {args.command!r}")
    except QueueError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2
    except KeyboardInterrupt:
        print("interrupted: local queue remains resumable", file=sys.stderr)
        return 130


if __name__ == "__main__":
    raise SystemExit(main())
