#!/usr/bin/env python3
"""Generate and evaluate the Risukun picture-book candidates.

The script deliberately keeps all generated files below ``generation/output``.
That directory is ignored by Git, so a failed API call can leave a retryable
state without making the repository dirty.  ``--dry-run`` only uses the
standard library and is useful for validating the storyboard before installing
the optional generation dependencies.
"""

from __future__ import annotations

import argparse
import ast
import base64
import binascii
import copy
import dataclasses
import datetime as dt
import difflib
import hashlib
import json
import os
import re
import shutil
import sys
import tempfile
import urllib.request
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Iterable, Mapping, Sequence


SCRIPT_PATH = Path(__file__).resolve()
STORYBOOK_DIR = SCRIPT_PATH.parents[2]
GENERATION_DIR = STORYBOOK_DIR / "generation"
PROMPTS_DIR = GENERATION_DIR / "prompts"
REFS_DIR = GENERATION_DIR / "refs"
OUTPUT_DIR = GENERATION_DIR / "output"

IMAGE_MODEL = "gpt-image-2"
EVALUATOR_MODEL = "gpt-5.6-sol"
IMAGE_SIZE = "2048x1152"
VARIANTS = ("a", "b", "c")
PAGE_ORDER = ("cover", "page01", *(f"page{i:02d}" for i in range(2, 12)))
DEFAULT_MAX_RETRIES = 2


class StorybookError(RuntimeError):
    """A user-actionable configuration or generation error."""


class DependencyError(StorybookError):
    """An optional runtime dependency is missing."""


@dataclass(frozen=True)
class VariantSpec:
    id: str
    shot: str
    composition: str
    focal_point: str


@dataclass(frozen=True)
class PageSpec:
    id: str
    locked: bool
    setting: str
    story_beat: str
    must_have: tuple[str, ...]
    must_not_have: tuple[str, ...]
    variants: Mapping[str, VariantSpec]
    environment_scale_min: float = 4.0


@dataclass(frozen=True)
class ReferenceImage:
    path: Path
    role: str


@dataclass
class CostBudget:
    """Conservative, configurable estimate used by ``--max-cost-usd``.

    The image API price can change independently of this repository.  The
    estimate is therefore intentionally explicit and can be overridden with
    environment variables rather than pretending to be an invoice.
    """

    limit: float | None
    image_estimate: float = 0.40
    evaluation_estimate: float = 0.05
    spent_estimate: float = 0.0

    @classmethod
    def from_args(cls, limit: float | None) -> "CostBudget":
        def env_float(name: str, default: float) -> float:
            value = os.environ.get(name)
            if value is None:
                return default
            try:
                parsed = float(value)
            except ValueError as exc:
                raise StorybookError(f"{name} must be a number, got {value!r}") from exc
            if parsed < 0:
                raise StorybookError(f"{name} must not be negative")
            return parsed

        if limit is not None and limit < 0:
            raise StorybookError("--max-cost-usd must not be negative")
        return cls(
            limit=limit,
            image_estimate=env_float("STORYBOOK_ESTIMATED_IMAGE_COST_USD", 0.40),
            evaluation_estimate=env_float("STORYBOOK_ESTIMATED_EVALUATION_COST_USD", 0.05),
        )

    def reserve(self, amount: float, label: str) -> bool:
        if self.limit is not None and self.spent_estimate + amount > self.limit + 1e-9:
            return False
        self.spent_estimate += amount
        return True

    def as_dict(self) -> dict[str, Any]:
        return {
            "limit_usd": self.limit,
            "image_estimate_usd": self.image_estimate,
            "evaluation_estimate_usd": self.evaluation_estimate,
            "spent_estimate_usd": round(self.spent_estimate, 6),
        }


@dataclass
class RunContext:
    storybook_dir: Path
    dry_run: bool
    quality: str
    max_retries: int
    regenerate: bool
    regenerate_locked: bool
    resume: bool
    client: Any = None
    budget: CostBudget | None = None
    state: dict[str, Any] = field(default_factory=dict)

    @property
    def generation_dir(self) -> Path:
        return self.storybook_dir / "generation"

    @property
    def prompts_dir(self) -> Path:
        return self.generation_dir / "prompts"

    @property
    def refs_dir(self) -> Path:
        return self.generation_dir / "refs"

    @property
    def output_dir(self) -> Path:
        return self.generation_dir / "output"

    @property
    def state_path(self) -> Path:
        return self.output_dir / ".state.json"


def now_iso() -> str:
    return dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds")


def atomic_write_json(path: Path, payload: Mapping[str, Any]) -> None:
    """Write JSON atomically so an interrupted run remains recoverable."""

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


def parse_scalar(value: str) -> Any:
    value = value.strip()
    if not value:
        return None
    if value in {"null", "Null", "NULL", "~"}:
        return None
    if value.lower() in {"true", "false"}:
        return value.lower() == "true"
    if value.startswith(("\"", "'")) and value[-1:] == value[0]:
        try:
            return ast.literal_eval(value)
        except (SyntaxError, ValueError):
            return value[1:-1]
    if value.startswith(("[", "{")):
        try:
            return json.loads(value)
        except json.JSONDecodeError:
            pass
    try:
        return int(value)
    except ValueError:
        try:
            return float(value)
        except ValueError:
            return value


def strip_yaml_comment(line: str) -> str:
    quote: str | None = None
    escaped = False
    for index, character in enumerate(line):
        if escaped:
            escaped = False
            continue
        if character == "\\" and quote == '"':
            escaped = True
            continue
        if character in {'"', "'"}:
            if quote is None:
                quote = character
            elif quote == character:
                quote = None
            continue
        if character == "#" and quote is None and (index == 0 or line[index - 1].isspace()):
            return line[:index].rstrip()
    return line.rstrip()


def find_mapping_colon(value: str) -> int:
    quote: str | None = None
    escaped = False
    for index, character in enumerate(value):
        if escaped:
            escaped = False
            continue
        if character == "\\" and quote == '"':
            escaped = True
            continue
        if character in {'"', "'"}:
            if quote is None:
                quote = character
            elif quote == character:
                quote = None
            continue
        if character == ":" and quote is None and (index + 1 == len(value) or value[index + 1].isspace()):
            return index
    return -1


def parse_minimal_yaml(text: str) -> Any:
    """Parse the small YAML subset used by storyboard.yaml.

    PyYAML remains the supported parser for arbitrary YAML.  This fallback is
    intentionally limited but lets ``--dry-run`` work on a clean Python
    installation, which is useful before installing generation dependencies.
    """

    lines: list[tuple[int, str]] = []
    for raw_line in text.splitlines():
        stripped = strip_yaml_comment(raw_line)
        if not stripped.strip():
            continue
        indent = len(stripped) - len(stripped.lstrip(" "))
        lines.append((indent, stripped[indent:]))

    def parse_block(position: int, indent: int) -> tuple[Any, int]:
        if position >= len(lines) or lines[position][0] < indent:
            return {}, position
        is_list = lines[position][0] == indent and lines[position][1].startswith("-")
        result: Any = [] if is_list else {}
        while position < len(lines):
            current_indent, content = lines[position]
            if current_indent < indent or current_indent != indent:
                break
            if is_list:
                if not content.startswith("-"):
                    break
                rest = content[1:].lstrip()
                position += 1
                colon = find_mapping_colon(rest)
                if colon >= 0:
                    key = rest[:colon].strip()
                    raw_value = rest[colon + 1 :].strip()
                    item: dict[str, Any] = {key: parse_scalar(raw_value)} if raw_value else {key: None}
                    if position < len(lines) and lines[position][0] > indent:
                        child_indent = lines[position][0]
                        child, position = parse_block(position, child_indent)
                        if isinstance(child, Mapping):
                            if not raw_value and key in child:
                                item[key] = child[key]
                                child = {k: v for k, v in child.items() if k != key}
                            item.update(child)
                    result.append(item)
                else:
                    if rest:
                        result.append(parse_scalar(rest))
                    elif position < len(lines) and lines[position][0] > indent:
                        child, position = parse_block(position, lines[position][0])
                        result.append(child)
                    else:
                        result.append(None)
            else:
                if content.startswith("-"):
                    break
                colon = find_mapping_colon(content)
                if colon < 0:
                    raise StorybookError(f"Cannot parse storyboard YAML line: {content!r}")
                key = content[:colon].strip()
                raw_value = content[colon + 1 :].strip()
                position += 1
                if raw_value:
                    result[key] = parse_scalar(raw_value)
                elif position < len(lines) and lines[position][0] > indent:
                    result[key], position = parse_block(position, lines[position][0])
                else:
                    result[key] = None
        return result, position

    parsed, position = parse_block(0, lines[0][0] if lines else 0)
    if position != len(lines):
        raise StorybookError("Could not parse the complete storyboard YAML")
    return parsed


def load_yaml(path: Path) -> Any:
    try:
        import yaml  # type: ignore
    except ImportError:
        return parse_minimal_yaml(path.read_text(encoding="utf-8"))
    try:
        return yaml.safe_load(path.read_text(encoding="utf-8"))
    except Exception as exc:  # pragma: no cover - exact parser exception varies
        raise StorybookError(f"Could not parse {path}: {exc}") from exc


def as_string(value: Any, field_name: str) -> str:
    if not isinstance(value, str) or not value.strip():
        raise StorybookError(f"Storyboard field {field_name!r} must be a non-empty string")
    return value.strip()


def as_string_tuple(value: Any, field_name: str) -> tuple[str, ...]:
    if not isinstance(value, list):
        raise StorybookError(f"Storyboard field {field_name!r} must be a list")
    return tuple(as_string(item, field_name) for item in value)


def as_bool(value: Any, field_name: str) -> bool:
    if not isinstance(value, bool):
        raise StorybookError(f"Storyboard field {field_name!r} must be true or false")
    return value


def as_float(value: Any, field_name: str) -> float:
    if isinstance(value, bool):
        raise StorybookError(f"Storyboard field {field_name!r} must be a number")
    try:
        parsed = float(value)
    except (TypeError, ValueError) as exc:
        raise StorybookError(f"Storyboard field {field_name!r} must be a number") from exc
    if not 0 <= parsed <= 5:
        raise StorybookError(f"Storyboard field {field_name!r} must be between 0 and 5")
    return parsed


def load_storyboard(path: Path) -> tuple[PageSpec, ...]:
    raw = load_yaml(path)
    if not isinstance(raw, Mapping) or not isinstance(raw.get("pages"), list):
        raise StorybookError(f"{path} must contain a pages list")
    pages: list[PageSpec] = []
    for raw_page in raw["pages"]:
        if not isinstance(raw_page, Mapping):
            raise StorybookError("Each storyboard page must be a mapping")
        page_id = as_string(raw_page.get("id"), "id")
        raw_variants = raw_page.get("variants")
        if not isinstance(raw_variants, Mapping):
            raise StorybookError(f"{page_id}: variants must be a mapping")
        variants: dict[str, VariantSpec] = {}
        for variant_id in VARIANTS:
            raw_variant = raw_variants.get(variant_id)
            if not isinstance(raw_variant, Mapping):
                raise StorybookError(f"{page_id}: missing variant {variant_id}")
            variants[variant_id] = VariantSpec(
                id=variant_id,
                shot=as_string(raw_variant.get("shot"), f"{page_id}.{variant_id}.shot"),
                composition=as_string(
                    raw_variant.get("composition"), f"{page_id}.{variant_id}.composition"
                ),
                focal_point=as_string(
                    raw_variant.get("focal_point"), f"{page_id}.{variant_id}.focal_point"
                ),
            )
        pages.append(
            PageSpec(
                id=page_id,
                locked=as_bool(raw_page.get("locked"), f"{page_id}.locked"),
                setting=as_string(raw_page.get("setting"), f"{page_id}.setting"),
                story_beat=as_string(raw_page.get("story_beat"), f"{page_id}.story_beat"),
                must_have=as_string_tuple(raw_page.get("must_have"), f"{page_id}.must_have"),
                must_not_have=as_string_tuple(
                    raw_page.get("must_not_have"), f"{page_id}.must_not_have"
                ),
                variants=variants,
                environment_scale_min=as_float(
                    raw_page.get("environment_scale_min", 4.0),
                    f"{page_id}.environment_scale_min",
                ),
            )
        )
    validate_storyboard(pages)
    return tuple(pages)


def validate_storyboard(pages: Sequence[PageSpec]) -> None:
    actual_ids = tuple(page.id for page in pages)
    expected_ids = PAGE_ORDER
    if actual_ids != expected_ids:
        raise StorybookError(
            "Storyboard page order must be "
            + ", ".join(expected_ids)
            + f"; got {', '.join(actual_ids)}"
        )
    locked = {page.id for page in pages if page.locked}
    if locked != {"cover", "page01"}:
        raise StorybookError("Only cover and page01 may be locked in storyboard.yaml")
    for page in pages:
        if tuple(page.variants) != VARIANTS:
            raise StorybookError(f"{page.id}: variants must be exactly a, b, c")


def load_style(path: Path) -> str:
    try:
        style = path.read_text(encoding="utf-8").strip()
    except OSError as exc:
        raise StorybookError(f"Could not read global style file {path}: {exc}") from exc
    if not style:
        raise StorybookError(f"Global style file {path} is empty")
    return style


def file_if_exists(path: Path) -> Path | None:
    return path if path.is_file() else None


def previous_candidate_path(context: RunContext, page_id: str, pages: Sequence[PageSpec]) -> Path | None:
    page_ids = [page.id for page in pages]
    try:
        page_index = page_ids.index(page_id)
    except ValueError:
        return None
    for earlier_id in reversed(page_ids[:page_index]):
        if earlier_id in {"cover", "page01"}:
            continue
        evaluation_path = context.output_dir / earlier_id / "evaluation.json"
        candidate_dir = context.output_dir / earlier_id
        candidates = [candidate_dir / f"variant_{variant}.png" for variant in VARIANTS]
        recommended: str | None = None
        if evaluation_path.is_file():
            try:
                evaluation = json.loads(evaluation_path.read_text(encoding="utf-8"))
                recommended = evaluation.get("recommended_variant")
            except (OSError, json.JSONDecodeError):
                recommended = None
        if recommended in VARIANTS and candidates[VARIANTS.index(recommended)].is_file():
            return candidates[VARIANTS.index(recommended)]
        for candidate in candidates:
            if candidate.is_file():
                return candidate
    return None


def select_references(
    context: RunContext, page: PageSpec, pages: Sequence[PageSpec]
) -> tuple[ReferenceImage, ...]:
    references: list[ReferenceImage] = []

    def add(filename: str, role: str) -> None:
        path = file_if_exists(context.refs_dir / filename)
        if path is not None and path not in {reference.path for reference in references}:
            references.append(ReferenceImage(path, role))

    add("cover_master.png", "canonical cover master: protagonist, world, palette, scale, and light")
    if page.id != "cover":
        add("page01_master.png", "canonical page01 master: protagonist and rabbit character design")
    if page.id == "page02":
        add("page02_ref_a.png", "supporting page02 continuity reference; do not copy its composition")
    elif page.id not in {"cover", "page01"}:
        previous = previous_candidate_path(context, page.id, pages)
        if previous is not None:
            references.append(
                ReferenceImage(
                    previous,
                    "previous-page continuity reference: preserve palette and character continuity, not framing",
                )
            )
    return tuple(references[:3])


def reference_role_text(references: Sequence[ReferenceImage]) -> str:
    if not references:
        return "No local reference image is available; follow the canonical written style exactly."
    lines = []
    for index, reference in enumerate(references, start=1):
        lines.append(f"Image {index} = {reference.role}. File: {reference.path.name}")
    return "\n".join(lines)


def build_prompt(
    page: PageSpec,
    variant: VariantSpec,
    style: str,
    references: Sequence[ReferenceImage],
    revision_instruction: str | None = None,
) -> str:
    """Build the seven ordered prompt sections required by Issue #28."""

    must_have = "\n".join(f"- {item}" for item in page.must_have)
    must_not_have = "\n".join(f"- {item}" for item in page.must_not_have)
    page_specific_constraint = ""
    if page.id == "page02":
        page_specific_constraint = (
            "\nThe acorn itself is underground and must not be visible above the soil; "
            "show only the tiny sprout."
        )
    revision = ""
    if revision_instruction:
        revision = (
            "\n\nRevision instruction from the strict evaluator. Correct these issues while "
            "preserving all hard constraints:\n"
            + revision_instruction.strip()
        )
    return "\n\n".join(
        (
            "1. REFERENCE IMAGE ROLES\n" + reference_role_text(references),
            "2. CANONICAL STYLE AND CHARACTER REQUIREMENTS\n" + style,
            "3. THIS PAGE'S STORY BEAT\n"
            f"Page: {page.id}\nSetting: {page.setting}\nStory beat: {page.story_beat}",
            "4. HARD CONSTRAINTS\n"
            "Must include:\n"
            + must_have
            + "\nMust not include:\n"
            + must_not_have
            + "\nThe generated image must contain illustration only; do not render story text, captions, logos, or watermarks."
            + page_specific_constraint,
            "5. THIS VARIANT'S EXACT COMPOSITION\n"
            f"Shot class: {variant.shot}\nComposition: {variant.composition}\nFocal point: {variant.focal_point}",
            "6. CONTINUITY\n"
            "Keep the established squirrel and rabbit designs, watercolor/colored-pencil medium, "
            "bright light, and story continuity consistent with the reference images. "
            "For close woodland scenes, show enormous trees through a close camera view rather "
            "than shrinking the characters.",
            "7. DO NOT COPY THE PREVIOUS COMPOSITION\n"
            "Use continuity references only for identity, palette, and visual language. "
            "Do not copy their framing, camera angle, subject placement, or composition. "
            "Make this variant visibly distinct from the other two variants.",
        )
    ) + revision


def prompt_hash(prompt: str) -> str:
    return hashlib.sha256(prompt.encode("utf-8")).hexdigest()


EVALUATION_SCHEMA: dict[str, Any] = {
    "type": "object",
    "additionalProperties": False,
    "properties": {
        "character_consistency": {"type": "number"},
        "style_consistency": {"type": "number"},
        "story_accuracy": {"type": "number"},
        "composition_quality": {"type": "number"},
        "composition_distinctness": {"type": "number"},
        "environment_scale": {"type": "number"},
        "continuity": {"type": "number"},
        "forbidden_artifacts": {"type": "array", "items": {"type": "string"}},
        "critique": {"type": "string"},
        "revision_instruction": {"type": "string"},
    },
    "required": [
        "character_consistency",
        "style_consistency",
        "story_accuracy",
        "composition_quality",
        "composition_distinctness",
        "environment_scale",
        "continuity",
        "forbidden_artifacts",
        "critique",
        "revision_instruction",
    ],
}


COMPARISON_SCHEMA: dict[str, Any] = {
    "type": "object",
    "additionalProperties": False,
    "properties": {
        "composition_classes": {
            "type": "object",
            "additionalProperties": {"type": "string"},
        },
        "too_similar_variants": {"type": "array", "items": {"type": "string"}},
        "critique": {"type": "string"},
        "revision_instructions": {
            "type": "object",
            "additionalProperties": {"type": "string"},
        },
    },
    "required": [
        "composition_classes",
        "too_similar_variants",
        "critique",
        "revision_instructions",
    ],
}


def evaluation_defaults() -> dict[str, Any]:
    return {
        "character_consistency": 0.0,
        "style_consistency": 0.0,
        "story_accuracy": 0.0,
        "composition_quality": 0.0,
        "composition_distinctness": 0.0,
        "environment_scale": 0.0,
        "continuity": 0.0,
        "forbidden_artifacts": [],
        "critique": "No evaluation was returned.",
        "revision_instruction": "Return a complete candidate that satisfies every storyboard constraint.",
    }


def normalize_evaluation(raw: Any) -> dict[str, Any]:
    if not isinstance(raw, Mapping):
        raise StorybookError("Vision evaluator returned a non-object JSON value")
    result = evaluation_defaults()
    for key in result:
        if key in raw:
            result[key] = raw[key]
    numeric_keys = (
        "character_consistency",
        "style_consistency",
        "story_accuracy",
        "composition_quality",
        "composition_distinctness",
        "environment_scale",
        "continuity",
    )
    for key in numeric_keys:
        try:
            value = float(result[key])
        except (TypeError, ValueError) as exc:
            raise StorybookError(f"Evaluator field {key!r} is not numeric") from exc
        result[key] = max(0.0, min(5.0, value))
    if not isinstance(result["forbidden_artifacts"], list):
        raise StorybookError("Evaluator field 'forbidden_artifacts' must be a list")
    result["forbidden_artifacts"] = [str(item) for item in result["forbidden_artifacts"]]
    result["critique"] = str(result["critique"])
    result["revision_instruction"] = str(result["revision_instruction"])
    return result


def passes_thresholds(page: PageSpec, evaluation: Mapping[str, Any]) -> tuple[bool, list[str]]:
    thresholds = {
        "character_consistency": 4.5,
        "style_consistency": 4.0,
        "story_accuracy": 4.0,
        "composition_quality": 4.0,
        "composition_distinctness": 4.0,
        "environment_scale": page.environment_scale_min,
    }
    failures = []
    for key, threshold in thresholds.items():
        try:
            value = float(evaluation.get(key, 0.0))
        except (TypeError, ValueError):
            value = 0.0
        if value < threshold:
            failures.append(f"{key}={value:.1f} < {threshold:.1f}")
    artifacts = evaluation.get("forbidden_artifacts", [])
    if artifacts:
        failures.append("forbidden_artifacts=" + ", ".join(str(item) for item in artifacts))
    return not failures, failures


def extract_json(text: str) -> Any:
    cleaned = text.strip()
    if cleaned.startswith("```"):
        cleaned = re.sub(r"^```(?:json)?\s*", "", cleaned, flags=re.IGNORECASE)
        cleaned = re.sub(r"\s*```$", "", cleaned)
    try:
        return json.loads(cleaned)
    except json.JSONDecodeError:
        start = cleaned.find("{")
        end = cleaned.rfind("}")
        if start >= 0 and end > start:
            try:
                return json.loads(cleaned[start : end + 1])
            except json.JSONDecodeError:
                pass
        raise StorybookError("Vision evaluator did not return valid JSON")


def response_text(response: Any) -> str:
    output_text = getattr(response, "output_text", None)
    if isinstance(output_text, str) and output_text.strip():
        return output_text
    # Compatibility fallback for SDK response objects that expose only output items.
    output = getattr(response, "output", None)
    if isinstance(output, list):
        chunks: list[str] = []
        for item in output:
            content = getattr(item, "content", None)
            if isinstance(content, list):
                for part in content:
                    text = getattr(part, "text", None)
                    if isinstance(text, str):
                        chunks.append(text)
        if chunks:
            return "\n".join(chunks)
    raise StorybookError("OpenAI Responses API returned no text")


def image_data_url(path: Path) -> str:
    try:
        data = base64.b64encode(path.read_bytes()).decode("ascii")
    except OSError as exc:
        raise StorybookError(f"Could not read candidate image {path}: {exc}") from exc
    suffix = path.suffix.lower()
    mime = "image/jpeg" if suffix in {".jpg", ".jpeg"} else "image/png"
    return f"data:{mime};base64,{data}"


def evaluate_candidate(
    client: Any, page: PageSpec, variant: VariantSpec, image_path: Path
) -> dict[str, Any]:
    prompt = f"""You are a strict art director reviewing one candidate page for a children's picture book.
Compare the candidate with the storyboard requirements below. Do not reward generic prettiness if it violates continuity, scale, story logic, or composition.

Page: {page.id}
Setting: {page.setting}
Story beat: {page.story_beat}
Requested shot: {variant.shot}
Requested composition: {variant.composition}
Focal point: {variant.focal_point}
Must have: {json.dumps(page.must_have, ensure_ascii=False)}
Must not have: {json.dumps(page.must_not_have, ensure_ascii=False)}

Check the established squirrel/rabbit character, watercolor + colored-pencil style, story accuracy, composition quality and distinctness, 10–15:1 environment scale when relevant, continuity, and forbidden artifacts. Return JSON only using the supplied schema. Scores are 0–5."""
    response = client.responses.create(
        model=EVALUATOR_MODEL,
        input=[
            {
                "role": "user",
                "content": [
                    {"type": "input_text", "text": prompt},
                    {"type": "input_image", "image_url": image_data_url(image_path)},
                ],
            }
        ],
        text={
            "format": {
                "type": "json_schema",
                "name": "storybook_candidate_evaluation",
                "strict": True,
                "schema": EVALUATION_SCHEMA,
            }
        },
    )
    return normalize_evaluation(extract_json(response_text(response)))


def deterministic_comparison(
    page: PageSpec, variants: Mapping[str, VariantSpec]
) -> dict[str, Any]:
    """Fallback comparison used when no evaluator response is available."""

    classes = {variant_id: spec.shot for variant_id, spec in variants.items()}
    too_similar: list[str] = []
    for left_index, left_id in enumerate(VARIANTS):
        for right_id in VARIANTS[left_index + 1 :]:
            left = variants.get(left_id)
            right = variants.get(right_id)
            if left is None or right is None:
                continue
            similarity = difflib.SequenceMatcher(
                None,
                f"{left.shot} {left.composition}",
                f"{right.shot} {right.composition}",
            ).ratio()
            if left.shot == right.shot or similarity >= 0.82:
                too_similar.extend(item for item in (left_id, right_id) if item not in too_similar)
    return {
        "composition_classes": classes,
        "too_similar_variants": too_similar,
        "critique": "Deterministic storyboard comparison; vision comparison is unavailable.",
        "revision_instructions": {
            variant_id: "Use a camera structure clearly different from the other variants."
            for variant_id in too_similar
        },
        "source": "storyboard",
    }


def compare_variants(
    client: Any,
    page: PageSpec,
    variant_images: Mapping[str, Path],
    variant_specs: Mapping[str, VariantSpec],
) -> dict[str, Any]:
    if client is None or len(variant_images) < 2:
        return deterministic_comparison(page, variant_specs)
    prompt = f"""You are comparing the three candidate illustrations for page {page.id} of a children's picture book.
The three candidates must have genuinely different camera structures, not merely different colors. Compare the uploaded images against these requested shot classes:
{json.dumps({key: value.shot for key, value in variant_specs.items()}, ensure_ascii=False)}

Identify variants that are materially too similar. Return JSON only with composition_classes, too_similar_variants, critique, and revision_instructions. Use only variant ids a, b, c."""
    content: list[dict[str, Any]] = [{"type": "input_text", "text": prompt}]
    for variant_id in VARIANTS:
        image = variant_images.get(variant_id)
        if image is not None:
            content.append({"type": "input_text", "text": f"Variant {variant_id}"})
            content.append({"type": "input_image", "image_url": image_data_url(image)})
    try:
        response = client.responses.create(
            model=EVALUATOR_MODEL,
            input=[{"role": "user", "content": content}],
            text={
                "format": {
                    "type": "json_schema",
                    "name": "storybook_variant_comparison",
                    "strict": True,
                    "schema": COMPARISON_SCHEMA,
                }
            },
        )
        raw = extract_json(response_text(response))
        if not isinstance(raw, Mapping):
            raise StorybookError("Variant comparison did not return an object")
        comparison = dict(raw)
        too_similar = comparison.get("too_similar_variants", [])
        comparison["too_similar_variants"] = [
            variant_id for variant_id in too_similar if variant_id in VARIANTS
        ]
        comparison["source"] = "vision"
        return comparison
    except Exception as exc:
        fallback = deterministic_comparison(page, variant_specs)
        fallback["vision_error"] = str(exc)
        return fallback


def make_client() -> Any:
    if not os.environ.get("OPENAI_API_KEY"):
        raise StorybookError(
            "OPENAI_API_KEY is not set. Use --dry-run to validate locally, or export the API key before generation."
        )
    try:
        from openai import OpenAI  # type: ignore
    except ImportError as exc:
        raise DependencyError(
            "The OpenAI SDK is missing. Install generation/requirements.txt, or use --dry-run."
        ) from exc
    try:
        return OpenAI(api_key=os.environ["OPENAI_API_KEY"])
    except Exception as exc:
        raise StorybookError(f"Could not initialize the OpenAI client: {exc}") from exc


def save_image_response(response: Any, output_path: Path) -> None:
    data_items = getattr(response, "data", None)
    if not data_items:
        raise StorybookError("OpenAI image edit returned no image data")
    item = data_items[0]
    encoded = getattr(item, "b64_json", None)
    if encoded:
        try:
            data = base64.b64decode(encoded)
        except (ValueError, binascii.Error):
            raise StorybookError("OpenAI image response contained invalid base64 data")
    else:
        url = getattr(item, "url", None)
        if not url:
            raise StorybookError("OpenAI image response contained neither b64_json nor url")
        try:
            with urllib.request.urlopen(url, timeout=120) as handle:  # noqa: S310 - API response URL
                data = handle.read()
        except Exception as exc:
            raise StorybookError(f"Could not download generated image: {exc}") from exc
    output_path.parent.mkdir(parents=True, exist_ok=True)
    temporary = output_path.with_suffix(output_path.suffix + ".tmp")
    temporary.write_bytes(data)
    os.replace(temporary, output_path)


def generate_image(
    client: Any,
    references: Sequence[ReferenceImage],
    prompt: str,
    quality: str,
    output_path: Path,
) -> None:
    handles = []
    try:
        for reference in references:
            handles.append(reference.path.open("rb"))
        response = client.images.edit(
            model=IMAGE_MODEL,
            image=handles,
            prompt=prompt,
            size=IMAGE_SIZE,
            quality=quality,
        )
        save_image_response(response, output_path)
    finally:
        for handle in handles:
            handle.close()


def initial_state(pages: Sequence[PageSpec]) -> dict[str, Any]:
    return {
        "schema_version": 1,
        "storybook": "risukun_hitotsu_no_donguri",
        "image_model": IMAGE_MODEL,
        "evaluator_model": EVALUATOR_MODEL,
        "updated_at": now_iso(),
        "pages": {
            page.id: {"status": "pending", "locked": page.locked, "variants": {}}
            for page in pages
        },
    }


def load_state(context: RunContext, pages: Sequence[PageSpec]) -> None:
    context.output_dir.mkdir(parents=True, exist_ok=True)
    state = initial_state(pages)
    if context.resume and context.state_path.is_file():
        try:
            loaded = json.loads(context.state_path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as exc:
            raise StorybookError(f"Could not read state file {context.state_path}: {exc}") from exc
        if isinstance(loaded, Mapping):
            state.update({key: value for key, value in loaded.items() if key != "pages"})
            if isinstance(loaded.get("pages"), Mapping):
                for page_id, page_state in loaded["pages"].items():
                    if page_id in state["pages"] and isinstance(page_state, Mapping):
                        state["pages"][page_id].update(copy.deepcopy(dict(page_state)))
    context.state = state


def save_state(context: RunContext) -> None:
    context.state["updated_at"] = now_iso()
    if context.budget is not None:
        context.state["cost"] = context.budget.as_dict()
    atomic_write_json(context.state_path, context.state)


def page_state(context: RunContext, page: PageSpec) -> dict[str, Any]:
    state = context.state.setdefault("pages", {}).setdefault(
        page.id, {"status": "pending", "locked": page.locked, "variants": {}}
    )
    state["locked"] = page.locked
    state.setdefault("variants", {})
    return state


def write_page_evaluation(context: RunContext, page: PageSpec, payload: Mapping[str, Any]) -> None:
    atomic_write_json(context.output_dir / page.id / "evaluation.json", payload)


def page_has_completed_variant(
    context: RunContext, page: PageSpec, variant_id: str, output_path: Path
) -> bool:
    if not context.resume or context.regenerate or not output_path.is_file():
        return False
    current = page_state(context, page).get("variants", {}).get(variant_id, {})
    return current.get("status") in {"passed", "existing"}


def candidate_from_state(
    context: RunContext, page: PageSpec, variant_id: str, output_path: Path
) -> dict[str, Any]:
    current = page_state(context, page).setdefault("variants", {}).setdefault(variant_id, {})
    current.update(
        {
            "output": str(output_path.relative_to(context.storybook_dir)),
            "updated_at": now_iso(),
        }
    )
    return current


def dry_run(
    context: RunContext,
    pages: Sequence[PageSpec],
    style: str,
    selected_variant: str | None,
    print_prompts: bool,
) -> int:
    print(f"DRY RUN: {len(pages)} page(s), quality={context.quality}, max_retries={context.max_retries}")
    print(f"models: image={IMAGE_MODEL}, evaluator={EVALUATOR_MODEL}, size={IMAGE_SIZE}")
    for page in pages:
        if page.locked and not context.regenerate_locked:
            print(f"SKIP locked {page.id} (use --regenerate-locked to include it)")
            continue
        references = select_references(context, page, pages)
        variants = [selected_variant] if selected_variant else list(VARIANTS)
        for variant_id in variants:
            variant = page.variants[variant_id]
            prompt = build_prompt(page, variant, style, references)
            print(
                f"PLAN {page.id}/{variant_id}: shot={variant.shot}; "
                f"refs={[reference.path.name for reference in references]}; prompt_sha256={prompt_hash(prompt)[:12]}"
            )
            if print_prompts:
                print(prompt)
                print("---")
    return 0


def maybe_make_contact_sheet(context: RunContext, page: PageSpec) -> str | None:
    try:
        from make_contact_sheet import make_contact_sheet  # type: ignore
    except ImportError:
        return "Pillow is not installed; contact_sheet.png was not created"
    try:
        output = make_contact_sheet(context.output_dir / page.id)
    except DependencyError as exc:
        return str(exc)
    except Exception as exc:
        return f"contact sheet failed: {exc}"
    return str(output.relative_to(context.storybook_dir))


def regenerate_similar_variant(
    context: RunContext,
    page: PageSpec,
    variant_id: str,
    pages: Sequence[PageSpec],
    style: str,
    references: Sequence[ReferenceImage],
    attempts_limit: int,
    revision_instruction: str,
    page_evaluations: dict[str, Any],
    variant_images: dict[str, Path],
) -> bool:
    """Spend one remaining retry on a variant flagged by the comparison pass."""

    candidate_state = page_state(context, page).setdefault("variants", {}).setdefault(variant_id, {})
    attempts = candidate_state.setdefault("attempts", [])
    previous_count = int(candidate_state.get("attempt_count", len(attempts)))
    if previous_count >= attempts_limit or variant_id not in variant_images:
        return False
    attempt_index = previous_count + 1
    variant = page.variants[variant_id]
    output_page_dir = context.output_dir / page.id
    prompt = build_prompt(page, variant, style, references, revision_instruction)
    attempt_path = output_page_dir / "attempts" / f"variant_{variant_id}_attempt_{attempt_index:02d}.png"
    attempt_record: dict[str, Any] = {
        "attempt": attempt_index,
        "started_at": now_iso(),
        "prompt_sha256": prompt_hash(prompt),
        "reason": "composition comparison flagged this variant as too similar",
    }
    attempts.append(attempt_record)
    candidate_state.update(
        {
            "status": "generating",
            "attempt_count": attempt_index,
            "prompt_sha256": prompt_hash(prompt),
            "attempts": attempts,
        }
    )
    save_state(context)
    if context.budget is not None and not context.budget.reserve(
        context.budget.image_estimate, f"{page.id}/{variant_id} comparison revision image"
    ):
        attempt_record.update(
            {
                "status": "budget_exceeded",
                "error": "Estimated cost limit reached before comparison revision",
                "retryable": False,
            }
        )
        candidate_state.update({"status": "budget_exceeded", "error": attempt_record["error"]})
        save_state(context)
        return False
    try:
        generate_image(context.client, references, prompt, context.quality, attempt_path)
        attempt_record["image"] = str(attempt_path.relative_to(context.storybook_dir))
    except Exception as exc:
        attempt_record.update({"status": "api_error", "error": str(exc), "retryable": True})
        candidate_state.update({"status": "retryable_error", "error": str(exc), "retryable": True})
        save_state(context)
        return False

    if context.budget is not None and not context.budget.reserve(
        context.budget.evaluation_estimate, f"{page.id}/{variant_id} comparison revision evaluation"
    ):
        attempt_record.update(
            {
                "status": "budget_exceeded",
                "error": "Estimated cost limit reached before comparison revision evaluation",
                "retryable": False,
            }
        )
        candidate_state.update({"status": "budget_exceeded", "error": attempt_record["error"]})
        save_state(context)
        return False
    try:
        evaluation = normalize_evaluation(evaluate_candidate(context.client, page, variant, attempt_path))
        passed, threshold_failures = passes_thresholds(page, evaluation)
        attempt_record.update(
            {
                "status": "passed" if passed else "needs_revision",
                "evaluation": evaluation,
                "threshold_failures": threshold_failures,
                "finished_at": now_iso(),
            }
        )
        page_evaluations[variant_id] = evaluation
        candidate_state.update(
            {
                "status": "passed" if passed else "needs_revision",
                "last_evaluation": evaluation,
                "retryable": not passed and attempt_index < attempts_limit,
                "error": None if passed else "; ".join(threshold_failures),
            }
        )
        if passed:
            shutil.copyfile(attempt_path, output_page_dir / f"variant_{variant_id}.png")
            variant_images[variant_id] = output_page_dir / f"variant_{variant_id}.png"
        else:
            candidate_state["status"] = "failed" if attempt_index >= attempts_limit else "needs_revision"
    except Exception as exc:
        attempt_record.update({"status": "evaluation_error", "error": str(exc), "retryable": True})
        candidate_state.update({"status": "retryable_error", "error": str(exc), "retryable": True})
        save_state(context)
        return False
    candidate_state["attempts"] = attempts
    candidate_state["updated_at"] = now_iso()
    atomic_write_json(output_page_dir / f"variant_{variant_id}.json", candidate_state)
    save_state(context)
    return passed


def run_page(
    context: RunContext,
    page: PageSpec,
    pages: Sequence[PageSpec],
    style: str,
    selected_variant: str | None,
) -> tuple[bool, dict[str, Any]]:
    state = page_state(context, page)
    output_page_dir = context.output_dir / page.id
    output_page_dir.mkdir(parents=True, exist_ok=True)
    state.update({"status": "running", "started_at": now_iso(), "error": None})
    save_state(context)

    references = select_references(context, page, pages)
    variant_ids = [selected_variant] if selected_variant else list(VARIANTS)
    attempts_limit = context.max_retries + 1
    page_evaluations: dict[str, Any] = {}
    variant_images: dict[str, Path] = {}
    failures = False

    for variant_id in variant_ids:
        variant = page.variants[variant_id]
        final_output = output_page_dir / f"variant_{variant_id}.png"
        candidate_state = candidate_from_state(context, page, variant_id, final_output)
        if page_has_completed_variant(context, page, variant_id, final_output):
            candidate_state["status"] = "existing"
            page_evaluations[variant_id] = candidate_state.get("last_evaluation", evaluation_defaults())
            variant_images[variant_id] = final_output
            print(f"RESUME {page.id}/{variant_id}: existing passed candidate")
            continue

        revision_instruction: str | None = None
        attempts: list[dict[str, Any]] = []
        passed = False
        for attempt_index in range(1, attempts_limit + 1):
            prompt = build_prompt(page, variant, style, references, revision_instruction)
            candidate_state.update(
                {
                    "status": "generating",
                    "attempts": attempts,
                    "attempt_count": attempt_index,
                    "prompt_sha256": prompt_hash(prompt),
                }
            )
            save_state(context)
            attempt_path = output_page_dir / "attempts" / f"variant_{variant_id}_attempt_{attempt_index:02d}.png"
            attempt_record: dict[str, Any] = {
                "attempt": attempt_index,
                "started_at": now_iso(),
                "prompt_sha256": prompt_hash(prompt),
            }
            attempts.append(attempt_record)
            if context.budget is not None and not context.budget.reserve(
                context.budget.image_estimate, f"{page.id}/{variant_id} image"
            ):
                error = "Estimated cost limit reached before image generation"
                attempt_record.update({"status": "budget_exceeded", "error": error, "retryable": False})
                candidate_state.update({"status": "budget_exceeded", "error": error})
                failures = True
                save_state(context)
                break
            try:
                generate_image(context.client, references, prompt, context.quality, attempt_path)
                attempt_record["image"] = str(attempt_path.relative_to(context.storybook_dir))
            except Exception as exc:
                error = str(exc)
                attempt_record.update({"status": "api_error", "error": error, "retryable": True})
                candidate_state.update({"status": "retryable_error", "error": error, "retryable": True})
                failures = True
                save_state(context)
                print(f"RETRYABLE ERROR {page.id}/{variant_id} attempt {attempt_index}: {error}")
                continue

            if context.budget is not None and not context.budget.reserve(
                context.budget.evaluation_estimate, f"{page.id}/{variant_id} evaluation"
            ):
                error = "Estimated cost limit reached before image evaluation"
                attempt_record.update({"status": "budget_exceeded", "error": error, "retryable": False})
                candidate_state.update({"status": "budget_exceeded", "error": error})
                failures = True
                save_state(context)
                break
            try:
                evaluation = normalize_evaluation(
                    evaluate_candidate(context.client, page, variant, attempt_path)
                )
                passed, threshold_failures = passes_thresholds(page, evaluation)
                attempt_record.update(
                    {
                        "status": "passed" if passed else "needs_revision",
                        "evaluation": evaluation,
                        "threshold_failures": threshold_failures,
                        "finished_at": now_iso(),
                    }
                )
                page_evaluations[variant_id] = evaluation
                revision_instruction = evaluation.get("revision_instruction")
                candidate_state.update(
                    {
                        "status": "passed" if passed else "needs_revision",
                        "last_evaluation": evaluation,
                        "retryable": not passed and attempt_index < attempts_limit,
                        "error": None if passed else "; ".join(threshold_failures),
                    }
                )
                if passed:
                    shutil.copyfile(attempt_path, final_output)
                    variant_images[variant_id] = final_output
                    break
                print(
                    f"REVISION {page.id}/{variant_id} attempt {attempt_index}: "
                    + "; ".join(threshold_failures)
                )
            except Exception as exc:
                error = str(exc)
                attempt_record.update({"status": "evaluation_error", "error": error, "retryable": True})
                candidate_state.update({"status": "retryable_error", "error": error, "retryable": True})
                failures = True
                save_state(context)
                print(f"RETRYABLE EVALUATION ERROR {page.id}/{variant_id}: {error}")

        if not passed:
            failures = True
            if candidate_state.get("status") not in {"retryable_error", "budget_exceeded"}:
                candidate_state["status"] = "failed"
            if attempt_path_is_file := next(
                (
                    output_page_dir / "attempts" / f"variant_{variant_id}_attempt_{index:02d}.png"
                    for index in range(len(attempts), 0, -1)
                    if (output_page_dir / "attempts" / f"variant_{variant_id}_attempt_{index:02d}.png").is_file()
                ),
                None,
            ):
                shutil.copyfile(attempt_path_is_file, final_output)
                variant_images[variant_id] = final_output
        candidate_state["attempts"] = attempts
        candidate_state["updated_at"] = now_iso()
        atomic_write_json(output_page_dir / f"variant_{variant_id}.json", candidate_state)
        save_state(context)

    comparison = compare_variants(context.client, page, variant_images, page.variants)
    too_similar = comparison.get("too_similar_variants", [])
    if too_similar:
        revision_instructions = comparison.get("revision_instructions", {})
        if not isinstance(revision_instructions, Mapping):
            revision_instructions = {}
        regenerated_any = False
        for variant_id in too_similar:
            if variant_id not in page.variants:
                continue
            regenerated_any = regenerate_similar_variant(
                context,
                page,
                variant_id,
                pages,
                style,
                references,
                attempts_limit,
                str(
                    revision_instructions.get(
                        variant_id,
                        "Change the camera angle, subject placement, depth layers, and focal point so this variant is visibly distinct.",
                    )
                ),
                page_evaluations,
                variant_images,
            ) or regenerated_any
        if regenerated_any:
            # Re-run the comparison once after the targeted revision. A single
            # pass keeps the retry budget bounded while making the comparison
            # result reflect the final files that remain for human review.
            comparison = compare_variants(context.client, page, variant_images, page.variants)
            too_similar = comparison.get("too_similar_variants", [])
        if too_similar:
            failures = True
            print(f"COMPOSITION WARNING {page.id}: variants too similar: {', '.join(too_similar)}")

    recommended_variant = recommend_variant(page, page_evaluations)
    evaluation_payload = {
        "schema_version": 1,
        "page": page.id,
        "generated_at": now_iso(),
        "thresholds": {
            "character_consistency": 4.5,
            "style_consistency": 4.0,
            "story_accuracy": 4.0,
            "composition_quality": 4.0,
            "composition_distinctness": 4.0,
            "environment_scale": page.environment_scale_min,
            "forbidden_artifacts": "empty",
        },
        "variants": page_evaluations,
        "variant_comparison": comparison,
        "recommended_variant": recommended_variant,
        "human_decision_required": True,
    }
    write_page_evaluation(context, page, evaluation_payload)
    sheet_warning = None
    if len(variant_images) >= 2:
        sheet_warning = maybe_make_contact_sheet(context, page)
        if sheet_warning:
            evaluation_payload["contact_sheet_warning"] = sheet_warning
            write_page_evaluation(context, page, evaluation_payload)
    state.update(
        {
            "status": "failed" if failures else "completed",
            "finished_at": now_iso(),
            "recommended_variant": recommended_variant,
            "variant_comparison": comparison,
        }
    )
    save_state(context)
    return not failures, evaluation_payload


def recommend_variant(page: PageSpec, evaluations: Mapping[str, Any]) -> str | None:
    scored: list[tuple[float, str]] = []
    for variant_id in VARIANTS:
        evaluation = evaluations.get(variant_id)
        if not isinstance(evaluation, Mapping):
            continue
        passed, _ = passes_thresholds(page, evaluation)
        if not passed:
            continue
        score = sum(
            float(evaluation.get(key, 0.0))
            for key in (
                "character_consistency",
                "style_consistency",
                "story_accuracy",
                "composition_quality",
                "composition_distinctness",
                "environment_scale",
                "continuity",
            )
        )
        scored.append((score, variant_id))
    return max(scored)[1] if scored else None


def selected_pages(
    pages: Sequence[PageSpec],
    page_id: str | None,
    from_page: str | None,
    to_page: str | None,
) -> tuple[PageSpec, ...]:
    by_id = {page.id: page for page in pages}
    if page_id and (from_page or to_page):
        raise StorybookError("--page cannot be combined with --from-page or --to-page")
    if page_id:
        if page_id not in by_id:
            raise StorybookError(f"Unknown page {page_id!r}; choose from {', '.join(by_id)}")
        return (by_id[page_id],)
    start = from_page or pages[0].id
    end = to_page or pages[-1].id
    if start not in by_id or end not in by_id:
        raise StorybookError("--from-page/--to-page must name storyboard pages")
    start_index = PAGE_ORDER.index(start)
    end_index = PAGE_ORDER.index(end)
    if start_index > end_index:
        raise StorybookError("--from-page must not come after --to-page")
    return tuple(pages[start_index : end_index + 1])


def adopt_candidate(
    context: RunContext,
    page_id: str,
    variant_id: str,
    force: bool,
) -> Path:
    source = context.output_dir / page_id / f"variant_{variant_id}.png"
    if not source.is_file():
        raise StorybookError(f"Candidate does not exist: {source}; generate it first")
    target = context.storybook_dir / "assets" / "risukun_hitotsu_no_donguri" / f"{page_id}.png"
    if target.exists() and not force:
        raise StorybookError(f"{target} already exists; use --force-adopt to replace it")
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(source, target)
    return target


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--page", help="Generate one page, for example page05")
    parser.add_argument("--variant", choices=VARIANTS, help="Only generate one variant")
    parser.add_argument("--from-page", help="Inclusive page range start")
    parser.add_argument("--to-page", help="Inclusive page range end")
    parser.add_argument("--quality", choices=("low", "medium", "high"), default="medium")
    parser.add_argument("--max-retries", type=int, default=DEFAULT_MAX_RETRIES)
    parser.add_argument("--max-cost-usd", type=float, default=None)
    parser.add_argument("--regenerate", action="store_true", help="Regenerate existing unlocked candidates")
    parser.add_argument(
        "--regenerate-locked",
        action="store_true",
        help="Allow regeneration of locked cover/page01 (still requires API access)",
    )
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--print-prompts", action="store_true", help="Print full prompts during dry-run")
    parser.add_argument("--adopt", action="store_true", help="Copy the selected candidate to final assets")
    parser.add_argument("--force-adopt", action="store_true", help="Allow --adopt to replace an existing asset")
    parser.add_argument("--no-resume", action="store_false", dest="resume", help="Ignore prior state and outputs")
    parser.add_argument(
        "--storybook-dir",
        type=Path,
        default=STORYBOOK_DIR,
        help=argparse.SUPPRESS,
    )
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    if args.max_retries < 0:
        parser.error("--max-retries must be zero or greater")
    if args.adopt and args.dry_run:
        parser.error("--adopt cannot be combined with --dry-run")
    if args.force_adopt and not args.adopt:
        parser.error("--force-adopt requires --adopt")
    try:
        storybook_dir = args.storybook_dir.resolve()
        pages = load_storyboard(storybook_dir / "generation" / "prompts" / "storyboard.yaml")
        style = load_style(storybook_dir / "generation" / "prompts" / "global_style.md")
        chosen_pages = selected_pages(pages, args.page, args.from_page, args.to_page)
        context = RunContext(
            storybook_dir=storybook_dir,
            dry_run=args.dry_run,
            quality=args.quality,
            max_retries=args.max_retries,
            regenerate=args.regenerate,
            regenerate_locked=args.regenerate_locked,
            resume=args.resume,
            budget=CostBudget.from_args(args.max_cost_usd),
        )
        if args.dry_run:
            return dry_run(context, chosen_pages, style, args.variant, args.print_prompts)
        if args.adopt:
            if len(chosen_pages) != 1 or not args.variant:
                raise StorybookError("--adopt requires exactly one --page and --variant")
            target = adopt_candidate(context, chosen_pages[0].id, args.variant, args.force_adopt)
            print(f"ADOPTED {chosen_pages[0].id}/{args.variant} -> {target}")
            return 0
        load_state(context, pages)
        # A locked-only inspection should remain useful without an API key. The
        # client is created before the first eligible page, so configuration
        # errors are reported before any network request.
        has_eligible_page = any(
            not page.locked or args.regenerate_locked for page in chosen_pages
        )
        save_state(context)
        if has_eligible_page:
            try:
                context.client = make_client()
            except StorybookError as exc:
                for page in chosen_pages:
                    if page.locked and not args.regenerate_locked:
                        continue
                    page_state(context, page).update(
                        {
                            "status": "retryable_error",
                            "error": str(exc),
                            "retryable": True,
                            "finished_at": now_iso(),
                        }
                    )
                save_state(context)
                raise
        failures = False
        for page in chosen_pages:
            if page.locked and not args.regenerate_locked:
                page_state(context, page).update(
                    {
                        "status": "locked",
                        "skip_reason": "locked canonical reference; use --regenerate-locked",
                        "finished_at": now_iso(),
                    }
                )
                save_state(context)
                print(f"SKIP locked {page.id} (use --regenerate-locked to include it)")
                continue
            succeeded, _ = run_page(context, page, pages, style, args.variant)
            failures = failures or not succeeded
        if failures:
            print("Completed with retryable or validation failures; inspect generation/output/.state.json")
            return 1
        print("Completed successfully. Review each contact_sheet.png and choose the final human-approved asset.")
        return 0
    except StorybookError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2
    except KeyboardInterrupt:
        print("interrupted: state was saved at the last completed boundary", file=sys.stderr)
        return 130


if __name__ == "__main__":
    raise SystemExit(main())
