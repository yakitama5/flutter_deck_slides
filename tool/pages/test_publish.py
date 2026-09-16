"""Exercise Pages isolation and authorization without GitHub or Flutter access."""

import copy
import io
import json
import os
import shutil
import stat
import tempfile
import unittest
import zipfile
from pathlib import Path
from unittest import mock

import publish
from select_preview_slides import select_slides


def archive(entries):
    output = io.BytesIO()
    with zipfile.ZipFile(output, "w") as zipped:
        for name, data in entries:
            zipped.writestr(name, data)
    return output.getvalue()


def write(root, name, contents):
    path = root / name
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(contents)


def pull(number=56, sha="preview-sha"):
    return {
        "number": number,
        "state": "open",
        "base": {"ref": "main"},
        "head": {
            "repo": {"full_name": "owner/slides"},
            "ref": f"preview-{number}",
            "sha": sha,
        },
    }


def build_run(production=False):
    return {
        "id": 123,
        "conclusion": "success",
        "repository": {"full_name": "owner/slides"},
        "head_repository": {"full_name": "owner/slides"},
        "path": ".github/workflows/deploy.yaml"
        if production
        else ".github/workflows/ci.yaml",
        "event": "push" if production else "pull_request",
        "head_branch": "main" if production else "preview-56",
        "head_sha": "main-sha" if production else "preview-sha",
        "pull_requests": [] if production else [{"number": 56}],
    }


class FakeGitHub:
    repo = "owner/slides"
    server = "https://github.com"

    def __init__(self, responses=None, open_pulls=None):
        self.responses = responses or {}
        self.open_pulls = [pull()] if open_pulls is None else open_pulls
        self.calls = []

    def request(self, path, body=None, raw=False):
        self.calls.append((path, body, raw))
        if path not in self.responses:
            raise AssertionError(f"Unexpected GitHub API request: {path}")
        result = self.responses[path]
        return result() if callable(result) else copy.deepcopy(result)

    def all(self, path):
        self.calls.append((path, None, False))
        if path in self.responses:
            return copy.deepcopy(self.responses[path])
        if path != "pulls?state=open&base=main":
            raise AssertionError(f"Unexpected paginated API request: {path}")
        return copy.deepcopy(self.open_pulls)


class StaticArchiveTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.destination = Path(self.temp.name) / "incoming"

    def test_regular_files_and_nested_assets_are_extracted(self):
        data = archive(
            [("index.html", "preview"), ("slide/assets/dashmaru.glb", "model")]
        )
        publish.unpack_static(data, self.destination)
        self.assertEqual((self.destination / "index.html").read_text(), "preview")
        self.assertEqual(
            (self.destination / "slide/assets/dashmaru.glb").read_text(), "model"
        )

    def test_unsafe_entries_reject_archive_before_writing_safe_files(self):
        for unsafe in [
            "../outside",
            "slide/../../outside",
            "/absolute",
            "slide\\..\\outside",
            ".git/config",
            "slide/.git/hooks/post-checkout",
            ".pages-state.json",
            "previews/pr-99/index.html",
            "control\nname",
        ]:
            with self.subTest(path=unsafe):
                data = archive([("index.html", "safe"), (unsafe, "unsafe")])
                with self.assertRaises(ValueError):
                    publish.unpack_static(data, self.destination)
                self.assertFalse(self.destination.exists())

    def test_symlinks_and_special_files_are_rejected(self):
        for mode in [stat.S_IFLNK | 0o777, stat.S_IFIFO | 0o600, stat.S_IFCHR | 0o600]:
            with self.subTest(mode=mode):
                item = zipfile.ZipInfo("linked-asset")
                item.create_system = 3
                item.external_attr = mode << 16
                data = archive([("index.html", "safe"), (item, "../../outside")])
                with self.assertRaises(ValueError):
                    publish.unpack_static(data, self.destination)
                self.assertFalse(self.destination.exists())

    def test_duplicate_normalized_paths_are_rejected(self):
        with self.assertRaises(ValueError):
            publish.unpack_static(
                archive([("index.html", "one"), ("./index.html", "two")]),
                self.destination,
            )
        self.assertFalse(self.destination.exists())

    def test_missing_index_and_oversized_archive_are_rejected(self):
        with self.assertRaises(ValueError):
            publish.unpack_static(
                archive([("slide/main.dart.js", "code")]), self.destination
            )
        with mock.patch.object(publish, "SITE_LIMIT", 4), self.assertRaises(ValueError):
            publish.unpack_static(
                archive([("index.html", "too long")]), self.destination
            )
        self.assertFalse(self.destination.exists())


class SitePreservationTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.site = self.root / "site"
        self.incoming = self.root / "incoming"
        for path, contents in {
            "index.html": "production",
            "old-slide/index.html": "old",
            ".git/config": "git metadata",
            publish.STATE_FILE: "state",
            "previews/pr-56/index.html": "preview 56",
            "previews/pr-56/old-asset.txt": "old preview asset",
            "previews/pr-57/index.html": "preview 57",
        }.items():
            write(self.site, path, contents)
        write(self.incoming, "index.html", "new index")
        write(self.incoming, "new-slide/index.html", "new slide")

    def test_production_replacement_preserves_multiple_previews_and_metadata(self):
        publish.replace_site(self.site, self.incoming)
        self.assertEqual((self.site / "index.html").read_text(), "new index")
        self.assertFalse((self.site / "old-slide").exists())
        for number in (56, 57):
            self.assertEqual(
                (self.site / f"previews/pr-{number}/index.html").read_text(),
                f"preview {number}",
            )
        self.assertEqual((self.site / ".git/config").read_text(), "git metadata")
        self.assertEqual((self.site / publish.STATE_FILE).read_text(), "state")

    def test_preview_replacement_preserves_production_and_other_pr(self):
        publish.replace_site(self.site, self.incoming, number=56)
        self.assertEqual((self.site / "index.html").read_text(), "production")
        self.assertEqual(
            (self.site / "previews/pr-57/index.html").read_text(), "preview 57"
        )
        self.assertEqual(
            (self.site / "previews/pr-56/index.html").read_text(), "new index"
        )
        self.assertFalse((self.site / "previews/pr-56/old-asset.txt").exists())

    def test_prune_removes_only_closed_pr_from_files_and_state(self):
        state = {"production": {"sha": "main"}, "previews": {"56": {}, "57": {}}}
        self.assertEqual(publish.prune_previews(self.site, state, {57, 58}), [56])
        self.assertFalse((self.site / "previews/pr-56").exists())
        self.assertTrue((self.site / "previews/pr-57/index.html").is_file())
        self.assertEqual(state, {"production": {"sha": "main"}, "previews": {"57": {}}})
        self.assertEqual((self.site / "index.html").read_text(), "production")


class PublicationIdentityTests(unittest.TestCase):
    def setUp(self):
        self.run = build_run()
        self.github = FakeGitHub({"pulls/56": pull()})

    def publication(self):
        return publish.publication(self.github, {"workflow_run": self.run})

    def test_current_same_repository_pr_is_authorized(self):
        result = self.publication()
        self.assertEqual(
            (result["number"], result["sha"], result["artifact"]),
            (56, "preview-sha", "web-preview"),
        )

    def test_stale_closed_fork_deleted_repo_and_wrong_base_are_rejected(self):
        variants = []
        for field, value in [
            ("sha", "new-sha"),
            ("repo", None),
            ("repo", {"full_name": "fork/slides"}),
        ]:
            pr = pull()
            pr["head"][field] = value
            variants.append(pr)
        closed = pull()
        closed["state"] = "closed"
        variants.append(closed)
        wrong_base = pull()
        wrong_base["base"]["ref"] = "release"
        variants.append(wrong_base)
        for pr in variants:
            with self.subTest(pr=pr):
                self.github.responses["pulls/56"] = pr
                self.assertIsNone(self.publication())

    def test_failed_runs_and_other_workflows_or_events_are_rejected(self):
        for field, value in [
            ("conclusion", "failure"),
            ("path", ".github/workflows/other.yaml"),
            ("event", "push"),
        ]:
            with self.subTest(field=field, value=value):
                self.run = build_run()
                self.run[field] = value
                self.assertIsNone(self.publication())

    def test_foreign_repository_run_is_rejected(self):
        self.run["repository"]["full_name"] = "another/repository"
        with self.assertRaises(ValueError):
            self.publication()

    def test_fork_run_cannot_impersonate_a_matching_same_repo_pr(self):
        self.run["pull_requests"] = []
        self.run["head_repository"] = {"full_name": "fork/slides"}
        self.assertIsNone(self.publication())
        self.assertFalse(self.github.calls)

    def test_empty_association_falls_back_to_matching_branch_repo_and_sha(self):
        self.run["pull_requests"] = []
        wrong_branch = pull(57)
        wrong_sha = pull(58, "different-sha")
        fork = pull(59)
        fork["head"]["repo"]["full_name"] = "fork/slides"
        self.github.open_pulls = [wrong_branch, wrong_sha, fork, pull()]
        self.assertEqual(self.publication()["number"], 56)

    def test_missing_or_ambiguous_associations_are_rejected(self):
        self.run["pull_requests"] = []
        self.github.open_pulls = []
        self.assertIsNone(self.publication())
        self.github.open_pulls = [pull(), pull()]
        self.assertIsNone(self.publication())
        self.run["pull_requests"] = [{"number": 56}, {"number": 57}]
        self.assertIsNone(self.publication())

    def test_production_requires_current_main_commit(self):
        self.run = build_run(production=True)
        self.github.responses["git/ref/heads/main"] = {"object": {"sha": "main-sha"}}
        self.assertEqual(self.publication()["artifact"], "web-production")
        self.github.responses["git/ref/heads/main"]["object"]["sha"] = "new-main-sha"
        self.assertIsNone(self.publication())
        self.run["head_sha"] = "new-main-sha"
        self.run["head_branch"] = "other"
        self.assertIsNone(self.publication())

    def test_manual_run_id_uses_the_same_validation(self):
        self.github.responses["actions/runs/123"] = self.run
        result = publish.publication(self.github, {"inputs": {"build_run_id": "123"}})
        self.assertEqual(result["number"], 56)
        self.github.responses["pulls/56"]["state"] = "closed"
        self.assertIsNone(
            publish.publication(self.github, {"inputs": {"build_run_id": "123"}})
        )


class PrepareIntegrationTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.work = Path(self.temp.name) / "pages-publication"
        self.saved = Path(self.temp.name) / "saved"
        write(self.saved, "index.html", "production")
        write(self.saved, "previews/pr-56/index.html", "old preview")
        write(self.saved, "previews/pr-57/index.html", "other preview")
        self.state = {
            "production": {"sha": "main"},
            "previews": {"56": {"sha": "old"}, "57": {"sha": "other"}},
        }
        self.github = FakeGitHub(
            {
                "pulls/56": pull(),
                "actions/runs/123/artifacts?per_page=100": {
                    "artifacts": [{"id": 900, "name": "web-preview", "expired": False}]
                },
                "actions/artifacts/900/zip": archive(
                    [("index.html", "new preview"), ("slide/index.html", "new slide")]
                ),
                "pages": {"html_url": "https://owner.github.io/slides/"},
                "deployments": {"id": 901},
                "deployments/901/statuses": {},
            },
            open_pulls=[pull(), pull(57)],
        )
        self.addCleanup(mock.patch.stopall)
        mock.patch.object(publish, "load_site", side_effect=self.load_site).start()
        self.git = mock.patch.object(publish, "git", return_value="").start()
        mock.patch.dict(
            os.environ,
            {
                "GITHUB_RUN_ID": "777",
                "RUNNER_TEMP": self.temp.name,
                "GITHUB_STEP_SUMMARY": str(Path(self.temp.name) / "summary.md"),
            },
        ).start()

    def load_site(self, github, site):
        shutil.copytree(self.saved, site)
        return copy.deepcopy(self.state)

    def prepare(self):
        return publish.prepare(self.github, {"workflow_run": build_run()}, self.work)

    def test_successful_preview_keeps_production_and_other_pr(self):
        result = self.prepare()
        public = Path(result["site"])
        self.assertTrue(result["ready"])
        self.assertEqual(
            result["url"], "https://owner.github.io/slides/previews/pr-56/"
        )
        self.assertEqual((public / "index.html").read_text(), "production")
        self.assertEqual(
            (public / "previews/pr-56/index.html").read_text(), "new preview"
        )
        self.assertEqual(
            (public / "previews/pr-57/index.html").read_text(), "other preview"
        )
        self.assertFalse((public / publish.STATE_FILE).exists())
        state = json.loads((self.work / "site" / publish.STATE_FILE).read_text())
        self.assertEqual(state["previews"]["56"], {"sha": "preview-sha", "run_id": 123})

    def test_changed_head_during_download_does_not_replace_preview(self):
        responses = iter([pull(), pull(56, "new-head")])
        self.github.responses["pulls/56"] = lambda: next(responses)
        result = self.prepare()
        self.assertNotIn("number", result)
        self.assertEqual(
            (Path(result["site"]) / "previews/pr-56/index.html").read_text(),
            "old preview",
        )

    def test_closed_during_download_is_pruned_instead_of_republished(self):
        closed = pull()
        closed["state"] = "closed"
        responses = iter([pull(), closed])
        self.github.responses["pulls/56"] = lambda: next(responses)
        self.github.open_pulls = [pull(57)]
        result = self.prepare()
        self.assertEqual(result["removed"], [56])
        self.assertNotIn("number", result)
        self.assertFalse((Path(result["site"]) / "previews/pr-56").exists())
        self.assertTrue((Path(result["site"]) / "previews/pr-57/index.html").is_file())

    def test_preview_cannot_publish_without_production(self):
        (self.saved / "index.html").unlink()
        with self.assertRaisesRegex(ValueError, "production first"):
            self.prepare()

    def test_duplicate_artifacts_are_rejected(self):
        items = self.github.responses["actions/runs/123/artifacts?per_page=100"][
            "artifacts"
        ]
        items.append({"id": 902, "name": "web-preview", "expired": False})
        with self.assertRaisesRegex(ValueError, "Multiple matching"):
            self.prepare()

    def test_failed_deployment_keeps_cleanup_pending_for_next_publication(self):
        self.github.open_pulls = [pull(57)]
        result = publish.prepare(self.github, {}, self.work)
        self.assertEqual(result["removed"], [56])
        publish.finish(self.github, result, succeeded=False)
        self.state = json.loads((self.work / "site" / publish.STATE_FILE).read_text())
        self.assertEqual(self.state["pending_cleanup"], [56])
        shutil.rmtree(self.saved)
        shutil.copytree(self.work / "site", self.saved)
        retried = publish.prepare(self.github, {}, Path(self.temp.name) / "retried")
        self.assertEqual(retried["removed"], [56])
        self.assertFalse((Path(retried["site"]) / "previews/pr-56").exists())

    def test_successful_deployment_deactivates_closed_pr_and_clears_pending_cleanup(
        self,
    ):
        self.github.open_pulls = [pull(57)]
        self.github.responses.update(
            {
                "deployments?environment=pr-56": [{"id": 800}, {"id": 801}],
                "deployments/800/statuses": {},
                "deployments/801/statuses": {},
            }
        )
        result = publish.prepare(self.github, {}, self.work)
        with mock.patch.object(publish, "authorize_git"):
            publish.finish(self.github, result, succeeded=True)
        state = json.loads((self.work / "site" / publish.STATE_FILE).read_text())
        self.assertEqual(state["pending_cleanup"], [])
        updates = [(path, body["state"]) for path, body, _ in self.github.calls if body]
        self.assertEqual(
            updates,
            [
                ("deployments/800/statuses", "inactive"),
                ("deployments/801/statuses", "inactive"),
            ],
        )
        self.assertTrue((self.work / "site/previews/pr-57/index.html").is_file())

    def test_reopened_pr_is_removed_from_pending_cleanup(self):
        self.state["pending_cleanup"] = [56]
        result = publish.prepare(self.github, {}, self.work)
        self.assertEqual(result["removed"], [])
        self.assertTrue((Path(result["site"]) / "previews/pr-56/index.html").is_file())


class SlideSelectionTests(unittest.TestCase):
    available = frozenset({"alpha", "beta", "gamma"})

    def test_slide_change_selects_only_affected_existing_apps(self):
        self.assertEqual(
            select_slides(
                [
                    "slides/beta/lib/main.dart",
                    "slides/alpha/assets/model.glb",
                    "slides/beta/pubspec.yaml",
                ],
                self.available,
            ),
            ["alpha", "beta"],
        )

    def test_shared_packages_tooling_workflows_and_dependencies_select_all(self):
        for path in [
            "packages/flutter_deck/lib/main.dart",
            "tool/build_web.dart",
            ".github/workflows/ci.yaml",
            ".private-assets/dashmaru.tar.gz.gpg",
            "pubspec.yaml",
            "pubspec.lock",
            "mise.toml",
            "analysis_options.yaml",
        ]:
            with self.subTest(path=path):
                self.assertEqual(
                    select_slides([path], self.available), ["alpha", "beta", "gamma"]
                )

    def test_unrelated_docs_do_not_trigger_build(self):
        self.assertEqual(
            select_slides(["README.md", "docs/workflow.md"], self.available), []
        )

    def test_deleted_slide_selects_remaining_apps_to_refresh_preview_index(self):
        self.assertEqual(
            select_slides(["slides/deleted/lib/main.dart"], self.available),
            ["alpha", "beta", "gamma"],
        )


if __name__ == "__main__":
    unittest.main()
