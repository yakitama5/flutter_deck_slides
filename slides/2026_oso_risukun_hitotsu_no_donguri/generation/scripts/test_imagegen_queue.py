from __future__ import annotations

import base64
import shutil
import tempfile
import unittest
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
import sys

sys.path.insert(0, str(SCRIPT_DIR))

import generate_storybook as storybook  # noqa: E402
import imagegen_queue as queue  # noqa: E402


STORYBOOK_DIR = SCRIPT_DIR.parents[1]
ONE_PIXEL_PNG = base64.b64decode(
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII="
)


class ImageGenQueueTest(unittest.TestCase):
    def make_storybook_copy(self, root: Path) -> tuple[tuple[storybook.PageSpec, ...], str]:
        (root / "generation" / "prompts").mkdir(parents=True)
        (root / "generation" / "refs").mkdir(parents=True)
        shutil.copyfile(
            STORYBOOK_DIR / "generation" / "prompts" / "storyboard.yaml",
            root / "generation" / "prompts" / "storyboard.yaml",
        )
        shutil.copyfile(
            STORYBOOK_DIR / "generation" / "prompts" / "global_style.md",
            root / "generation" / "prompts" / "global_style.md",
        )
        for reference in (
            "cover_master.png",
            "page01_master.png",
            "page02_ref_a.png",
            "page02_ref_b.png",
        ):
            shutil.copyfile(
                STORYBOOK_DIR / "generation" / "refs" / reference,
                root / "generation" / "refs" / reference,
            )
        pages = storybook.load_storyboard(root / "generation" / "prompts" / "storyboard.yaml")
        style = storybook.load_style(root / "generation" / "prompts" / "global_style.md")
        return pages, style

    def test_prepare_record_review_and_next_page(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            pages, style = self.make_storybook_copy(root)
            state = queue.load_queue(root, pages, max_retries=1)
            page02 = pages[2]

            jobs = queue.prepare_page(
                root,
                state,
                pages,
                page02,
                style,
                None,
                "medium",
                False,
                False,
            )
            self.assertEqual([job["variant"] for job in jobs], ["a", "b", "c"])
            self.assertTrue((root / jobs[0]["job_file"]).is_file())
            self.assertIn("$imagegen", (root / jobs[0]["job_file"]).read_text())

            source = root / "source.png"
            source.write_bytes(ONE_PIXEL_PNG)
            for job in jobs:
                queue.record_job(root, state, pages, job["id"], source, False)

            queue.refresh_all_page_statuses(root, state, pages)
            self.assertEqual(state["pages"]["page02"]["status"], "ready_for_review")
            self.assertTrue(
                (root / "generation" / "output" / "page02" / "builtin_review.json").is_file()
            )
            for variant in storybook.VARIANTS:
                self.assertTrue(
                    (root / "generation" / "output" / "page02" / f"variant_{variant}.png").is_file()
                )

            next_page = queue.next_page_to_prepare(root, state, pages)
            self.assertEqual(next_page.id if next_page else None, "page03")
            page03_jobs = queue.prepare_page(
                root,
                state,
                pages,
                next_page,
                style,
                "a",
                "medium",
                False,
                False,
            )
            self.assertEqual(len(page03_jobs), 1)
            reference_paths = {item["path"] for item in page03_jobs[0]["references"]}
            self.assertIn("generation/output/page02/variant_a.png", reference_paths)

    def test_revision_is_bounded_and_keeps_original_job(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            pages, style = self.make_storybook_copy(root)
            state = queue.load_queue(root, pages, max_retries=1)
            page02 = pages[2]
            jobs = queue.prepare_page(
                root,
                state,
                pages,
                page02,
                style,
                "a",
                "medium",
                False,
                False,
            )
            source = root / "source.png"
            source.write_bytes(ONE_PIXEL_PNG)
            queue.record_job(root, state, pages, jobs[0]["id"], source, False)

            revision = queue.revise_job(
                root,
                state,
                pages,
                style,
                "page02",
                "a",
                "move the squirrel farther right and keep the sprout visible",
                "medium",
            )
            self.assertEqual(revision["attempt"], 2)
            self.assertEqual(revision["status"], queue.JOB_PENDING)
            self.assertIn("move the squirrel farther right", revision["prompt"])
            self.assertEqual(len(queue.jobs_for(state, "page02", "a")), 2)

            with self.assertRaises(queue.QueueError):
                queue.revise_job(
                    root,
                    state,
                    pages,
                    style,
                    "page02",
                    "a",
                    "one more revision",
                    "medium",
                )


if __name__ == "__main__":
    unittest.main()
