#!/usr/bin/env python3
"""Publish static artifacts without executing PR code or replacing other previews.

Run only from the default branch in the privileged Pages workflow. gh-pages is
the persistent static site; source code and model inputs stay on main.
"""

import base64
import io
import json
import os
import shutil
import stat
import subprocess
import sys
import urllib.error
import urllib.request
import zipfile
from pathlib import Path, PurePosixPath

SITE_LIMIT = 950_000_000
STATE_FILE = ".pages-state.json"
PREVIEWS = "previews"


def unpack_static(data, destination):
    """Validate the entire archive before writing any untrusted static files."""
    with zipfile.ZipFile(io.BytesIO(data)) as archive:
        total = 0
        seen = set()
        for item in archive.infolist():
            path = PurePosixPath(item.filename)
            mode = item.external_attr >> 16
            if (
                not path.parts
                or path.is_absolute()
                or "\\" in item.filename
                or any(p in (".", "..") or p.startswith(".") for p in path.parts)
                or any(ord(c) < 32 for c in item.filename)
                or path.parts[0] == PREVIEWS
                or stat.S_ISLNK(mode)
                or (stat.S_IFMT(mode) not in (0, stat.S_IFREG, stat.S_IFDIR))
                or str(path) in seen
            ):
                raise ValueError(f"Unsafe artifact entry: {item.filename!r}")
            seen.add(str(path))
            total += item.file_size
            if total > SITE_LIMIT:
                raise ValueError("Artifact exceeds the Pages size budget")
        if "index.html" not in seen:
            raise ValueError("Artifact has no index.html")
        destination.mkdir(parents=True, exist_ok=True)
        for item in archive.infolist():
            target = destination / item.filename
            if item.is_dir():
                target.mkdir(parents=True, exist_ok=True)
            else:
                target.parent.mkdir(parents=True, exist_ok=True)
                with archive.open(item) as source, target.open("wb") as output:
                    shutil.copyfileobj(source, output)


def remove(path):
    if path.is_dir():
        shutil.rmtree(path)
    elif path.exists():
        path.unlink()


def replace_site(site, incoming, number=None):
    if number is not None:
        destination = site / PREVIEWS / f"pr-{int(number)}"
        remove(destination)
        shutil.copytree(incoming, destination)
        return
    for item in site.iterdir():
        if item.name not in (".git", PREVIEWS, STATE_FILE):
            remove(item)
    for item in incoming.iterdir():
        if item.is_dir():
            shutil.copytree(item, site / item.name)
        else:
            shutil.copy2(item, site / item.name)


def prune_previews(site, state, open_numbers):
    removed = []
    for number in list(state["previews"]):
        if int(number) not in open_numbers:
            remove(site / PREVIEWS / f"pr-{int(number)}")
            del state["previews"][number]
            removed.append(int(number))
    return removed


class GitHub:
    def __init__(self):
        self.repo = os.environ["GITHUB_REPOSITORY"]
        self.token = os.environ["GH_TOKEN"]
        self.api = os.environ.get("GITHUB_API_URL", "https://api.github.com")
        self.server = os.environ.get("GITHUB_SERVER_URL", "https://github.com")

    def request(self, path, body=None, raw=False):
        url = f"{self.api}/repos/{self.repo}/{path}"
        request = urllib.request.Request(
            url,
            data=None if body is None else json.dumps(body).encode(),
            headers={
                "Authorization": f"Bearer {self.token}",
                "Accept": "application/vnd.github+json",
                "X-GitHub-Api-Version": "2022-11-28",
                "Content-Type": "application/json",
            },
        )
        # Artifact redirects go to signed blob URLs; never forward credentials.
        if raw:

            class NoRedirect(urllib.request.HTTPRedirectHandler):
                def redirect_request(self, req, fp, code, msg, headers, newurl):
                    return None

            try:
                response = urllib.request.build_opener(NoRedirect).open(
                    request, timeout=60
                )
            except urllib.error.HTTPError as error:
                if error.code != 302:
                    raise
                target = error.headers["Location"]
                if not target.startswith("https://"):
                    raise ValueError("Artifact redirect must use HTTPS") from error
                response = urllib.request.urlopen(target, timeout=60)
            with response:
                return response.read(SITE_LIMIT + 1)
        with urllib.request.urlopen(request, timeout=60) as response:
            return json.load(response)

    def all(self, path):
        result = []
        for page in range(1, 1001):
            separator = "&" if "?" in path else "?"
            batch = self.request(f"{path}{separator}per_page=100&page={page}")
            result.extend(batch)
            if len(batch) < 100:
                return result
        raise ValueError("GitHub pagination exceeded limit")


def git(site, *args):
    result = subprocess.run(
        ["git", "-C", str(site), *args],
        check=False,
        text=True,
        capture_output=True,
    )
    if result.returncode:
        raise RuntimeError(f"Git {args[0]} failed: {result.stderr.strip()}")
    return result.stdout.strip()


def authorize_git(github):
    # Keep the short-lived token in the process environment, never in the repo.
    credential = base64.b64encode(f"x-access-token:{github.token}".encode()).decode()
    os.environ.update(
        GIT_CONFIG_COUNT="1",
        GIT_CONFIG_KEY_0=f"http.{github.server}/.extraheader",
        GIT_CONFIG_VALUE_0=f"AUTHORIZATION: basic {credential}",
    )


def load_site(github, site):
    site.mkdir(parents=True)
    git(site, "init", "--initial-branch=gh-pages")
    git(site, "remote", "add", "origin", f"{github.server}/{github.repo}.git")
    authorize_git(github)
    try:
        github.request("git/ref/heads/gh-pages")
    except urllib.error.HTTPError as error:
        if error.code != 404:
            raise
    else:
        git(site, "fetch", "--depth=1", "origin", "gh-pages")
        git(site, "checkout", "-B", "gh-pages", "FETCH_HEAD")
    git(site, "config", "user.name", "github-actions[bot]")
    git(
        site,
        "config",
        "user.email",
        "41898282+github-actions[bot]@users.noreply.github.com",
    )
    path = site / STATE_FILE
    return json.loads(path.read_text()) if path.exists() else {"previews": {}}


def publication(github, event):
    """Derive identity from GitHub, never from files produced by a PR."""
    run = event.get("workflow_run")
    if event.get("inputs", {}).get("build_run_id"):
        run_id = int(event["inputs"]["build_run_id"])
        run = github.request(f"actions/runs/{run_id}")
    if not run or run["conclusion"] != "success":
        return None
    if run["repository"]["full_name"] != github.repo:
        raise ValueError("Build belongs to another repository")
    if (run.get("head_repository") or {}).get("full_name") != github.repo:
        print("Skipping a build whose source is a fork")
        return None
    if run["path"] == ".github/workflows/deploy.yaml" and run["event"] in (
        "push",
        "workflow_dispatch",
    ):
        head = github.request("git/ref/heads/main")["object"]["sha"]
        if run["head_branch"] != "main" or run["head_sha"] != head:
            print("Skipping an outdated production build")
            return None
        return {"run": run, "artifact": "web-production", "sha": head}
    if run["path"] != ".github/workflows/ci.yaml" or run["event"] != "pull_request":
        return None
    pulls = run.get("pull_requests", [])
    # GitHub can omit this array (for example on a rerun). Resolve only an open
    # PR whose repository, branch, and commit all match the authoritative run.
    if not pulls:
        pulls = [
            pr
            for pr in github.all("pulls?state=open&base=main")
            if pr["head"]["repo"] is not None
            and pr["head"]["repo"]["full_name"] == github.repo
            and pr["head"]["ref"] == run["head_branch"]
            and pr["head"]["sha"] == run["head_sha"]
        ]
    if len(pulls) != 1:
        print("Skipping a build without one associated pull request")
        return None
    pr = github.request(f"pulls/{int(pulls[0]['number'])}")
    if (
        pr["state"] != "open"
        or pr["base"]["ref"] != "main"
        or pr["head"]["repo"] is None
        or pr["head"]["repo"]["full_name"] != github.repo
        or pr["head"]["sha"] != run["head_sha"]
    ):
        print("Skipping a closed, outdated, or fork PR build")
        return None
    return {
        "run": run,
        "artifact": "web-preview",
        "sha": pr["head"]["sha"],
        "number": pr["number"],
    }


def prepare(github, event, work):
    publish = publication(github, event)
    site = work / "site"
    state = load_site(github, site)
    result = {"removed": [], "ready": False}
    if publish:
        run = publish["run"]
        artifacts = github.request(f"actions/runs/{run['id']}/artifacts?per_page=100")[
            "artifacts"
        ]
        matches = [
            a
            for a in artifacts
            if a["name"] == publish["artifact"] and not a["expired"]
        ]
        if len(matches) == 1:
            incoming = work / "incoming"
            unpack_static(
                github.request(f"actions/artifacts/{matches[0]['id']}/zip", raw=True),
                incoming,
            )
            number = publish.get("number")
            if number is not None and not (site / "index.html").exists():
                raise ValueError(
                    "Publish production first, then rerun the preview publisher"
                )
            # Check again after downloading; a PR can close/change during a build.
            if publication(github, event) == publish:
                replace_site(site, incoming, number)
                metadata = {"sha": publish["sha"], "run_id": run["id"]}
                if number is None:
                    state["production"] = metadata
                else:
                    state["previews"][str(number)] = metadata
                    result.update(number=number, sha=publish["sha"])
        elif matches:
            raise ValueError("Multiple matching build artifacts")
        else:
            print("No preview artifact (no web changes, or expired build)")
    open_numbers = {pr["number"] for pr in github.all("pulls?state=open&base=main")}
    removed = prune_previews(site, state, open_numbers)
    # Keep cleanup pending until the Pages deploy and Deployment API updates
    # succeed, so a failed publication can be safely retried.
    state["pending_cleanup"] = sorted(
        (set(state.get("pending_cleanup", [])) | set(removed)) - open_numbers
    )
    result["removed"] = state["pending_cleanup"]
    if not (site / "index.html").exists():
        print("No production site yet; nothing to publish")
        return result
    (site / STATE_FILE).write_text(json.dumps(state, indent=2) + "\n")
    (site / ".nojekyll").touch()
    size = sum(
        p.stat().st_size
        for p in site.rglob("*")
        if p.is_file() and ".git" not in p.relative_to(site).parts
    )
    if size > SITE_LIMIT:
        raise ValueError(
            f"Site is {size} bytes; close unused previews before retrying (limit {SITE_LIMIT})"
        )
    # This is an isolated generated-site repository, never the source checkout.
    paths = sorted(p.name for p in site.iterdir() if p.name != ".git")
    git(site, "add", "--", *paths)
    # Stage deleted files explicitly too, without adding arbitrary source files.
    deleted = git(site, "ls-files", "--deleted").splitlines()
    if deleted:
        git(site, "add", "--", *deleted)
    if git(site, "diff", "--cached", "--name-only"):
        git(
            site,
            "commit",
            "-m",
            f"Publish Pages from workflow {os.environ['GITHUB_RUN_ID']}",
        )
        git(site, "push", "origin", "HEAD:gh-pages")
    output = work / "public"
    shutil.copytree(site, output, ignore=shutil.ignore_patterns(".git", STATE_FILE))
    pages_url = github.request("pages")["html_url"].rstrip("/")
    result.update(ready=True, site=str(output))
    if "number" in result:
        number = result["number"]
        result["url"] = f"{pages_url}/{PREVIEWS}/pr-{number}/"
        deployment = github.request(
            "deployments",
            {
                "ref": result["sha"],
                "auto_merge": False,
                "required_contexts": [],
                "environment": f"pr-{number}",
                "transient_environment": True,
                "production_environment": False,
                "description": f"PR #{number} Web preview",
            },
        )
        result["deployment_id"] = deployment["id"]
        github.request(
            f"deployments/{deployment['id']}/statuses",
            {
                "state": "in_progress",
                "environment_url": result["url"],
                "auto_inactive": False,
            },
        )
    return result


def finish(github, result, succeeded):
    log_url = (
        f"{github.server}/{github.repo}/actions/runs/{os.environ['GITHUB_RUN_ID']}"
    )
    if "deployment_id" in result:
        github.request(
            f"deployments/{result['deployment_id']}/statuses",
            {
                "state": "success" if succeeded else "failure",
                "log_url": log_url,
                "environment_url": result["url"],
                "auto_inactive": True,
            },
        )
    if succeeded:
        if "deployment_id" in result:
            for deployment in github.all(
                f"deployments?environment=pr-{result['number']}"
            ):
                if deployment["id"] != result["deployment_id"]:
                    github.request(
                        f"deployments/{deployment['id']}/statuses",
                        {
                            "state": "inactive",
                            "auto_inactive": False,
                            "log_url": log_url,
                        },
                    )
        for number in result["removed"]:
            for deployment in github.all(f"deployments?environment=pr-{number}"):
                github.request(
                    f"deployments/{deployment['id']}/statuses",
                    {
                        "state": "inactive",
                        "auto_inactive": False,
                        "log_url": log_url,
                    },
                )
        if result["removed"]:
            site = Path(os.environ["RUNNER_TEMP"]) / "pages-publication" / "site"
            state = json.loads((site / STATE_FILE).read_text())
            state["pending_cleanup"] = []
            (site / STATE_FILE).write_text(json.dumps(state, indent=2) + "\n")
            authorize_git(github)
            git(site, "add", "--", STATE_FILE)
            git(site, "commit", "-m", "Record completed PR preview cleanup")
            git(site, "push", "origin", "HEAD:gh-pages")
    summary = Path(os.environ["GITHUB_STEP_SUMMARY"])
    with summary.open("a") as output:
        if "url" in result:
            output.write(
                f"### PR #{result['number']} preview\n\n[{result['url']}]({result['url']})\n\nCommit: `{result['sha']}`\n"
            )
        if succeeded and result["removed"]:
            output.write(f"\nClosed PR previews removed: {result['removed']}\n")


def main():
    github = GitHub()
    work = Path(os.environ["RUNNER_TEMP"]) / "pages-publication"
    result_path = work / "result.json"
    if len(sys.argv) > 1 and sys.argv[1] == "finish":
        if result_path.exists():
            finish(
                github,
                json.loads(result_path.read_text()),
                os.environ.get("PAGES_RESULT") == "success",
            )
        return
    event = json.loads(Path(os.environ["GITHUB_EVENT_PATH"]).read_text())
    result = prepare(github, event, work)
    work.mkdir(parents=True, exist_ok=True)
    result_path.write_text(json.dumps(result))
    with open(os.environ["GITHUB_OUTPUT"], "a") as output:
        output.write(f"ready={str(result['ready']).lower()}\n")
        if result["ready"]:
            output.write(f"site={result['site']}\n")


if __name__ == "__main__":
    main()
