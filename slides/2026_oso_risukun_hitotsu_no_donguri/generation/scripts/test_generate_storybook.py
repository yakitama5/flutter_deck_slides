from __future__ import annotations

import base64
import json
import shutil
import sys
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace


SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))

import generate_storybook as storybook  # noqa: E402


STORYBOOK_DIR = SCRIPT_DIR.parents[1]
ONE_PIXEL_PNG = base64.b64decode(
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII="
)


class FakeImages:
    def __init__(self) -> None:
        self.calls: list[dict[str, object]] = []

    def edit(self, **kwargs: object) -> SimpleNamespace:
        self.calls.append(kwargs)
        return SimpleNamespace(data=[SimpleNamespace(b64_json=base64.b64encode(ONE_PIXEL_PNG).decode())])


class FakeResponses:
    def __init__(self) -> None:
        self.calls: list[dict[str, object]] = []

    def create(self, **kwargs: object) -> SimpleNamespace:
        self.calls.append(kwargs)
        text = kwargs.get("text", {})
        format_name = ""
        if isinstance(text, dict):
            nested = text.get("format", {})
            if isinstance(nested, dict):
                format_name = str(nested.get("name", ""))
        if format_name == "storybook_variant_comparison":
            payload = {
                "composition_classes": {"a": "a", "b": "b", "c": "c"},
                "too_similar_variants": [],
                "critique": "distinct",
                "revision_instructions": {},
            }
        else:
            payload = {
                "character_consistency": 5,
                "style_consistency": 5,
                "story_accuracy": 5,
                "composition_quality": 5,
                "composition_distinctness": 5,
                "environment_scale": 5,
                "continuity": 5,
                "forbidden_artifacts": [],
                "critique": "pass",
                "revision_instruction": "",
            }
        return SimpleNamespace(output_text=json.dumps(payload))


class FakeClient:
    def __init__(self) -> None:
        self.images = FakeImages()
        self.responses = FakeResponses()


class SimilarityResponses(FakeResponses):
    def __init__(self) -> None:
        super().__init__()
        self.comparison_count = 0

    def create(self, **kwargs: object) -> SimpleNamespace:
        text = kwargs.get("text", {})
        format_name = ""
        if isinstance(text, dict):
            nested = text.get("format", {})
            if isinstance(nested, dict):
                format_name = str(nested.get("name", ""))
        if format_name == "storybook_variant_comparison":
            self.calls.append(kwargs)
            self.comparison_count += 1
            payload = {
                "composition_classes": {"a": "same", "b": "b", "c": "c"},
                "too_similar_variants": ["a"] if self.comparison_count == 1 else [],
                "critique": "revise once",
                "revision_instructions": {"a": "Use a high-angle detail instead."},
            }
            return SimpleNamespace(output_text=json.dumps(payload))
        return super().create(**kwargs)


class SimilarityClient(FakeClient):
    def __init__(self) -> None:
        self.images = FakeImages()
        self.responses = SimilarityResponses()


class StorybookTest(unittest.TestCase):
    def test_storyboard_contains_locked_pages_and_three_variants(self) -> None:
        pages = storybook.load_storyboard(
            STORYBOOK_DIR / "generation" / "prompts" / "storyboard.yaml"
        )
        self.assertEqual(tuple(page.id for page in pages), storybook.PAGE_ORDER)
        self.assertEqual({page.id for page in pages if page.locked}, {"cover", "page01"})
        self.assertEqual(set(pages[2].variants), set(storybook.VARIANTS))
        self.assertIn("the acorn visible above ground", pages[2].must_not_have)

    def test_prompt_sections_are_ordered_and_explicit(self) -> None:
        pages = storybook.load_storyboard(
            STORYBOOK_DIR / "generation" / "prompts" / "storyboard.yaml"
        )
        page = pages[2]
        prompt = storybook.build_prompt(
            page,
            page.variants["b"],
            "canonical style",
            (storybook.ReferenceImage(Path("cover_master.png"), "canonical master"),),
        )
        markers = [
            "1. REFERENCE IMAGE ROLES",
            "2. CANONICAL STYLE",
            "3. THIS PAGE'S STORY BEAT",
            "4. HARD CONSTRAINTS",
            "5. THIS VARIANT'S EXACT COMPOSITION",
            "6. CONTINUITY",
            "7. DO NOT COPY THE PREVIOUS COMPOSITION",
        ]
        positions = [prompt.index(marker) for marker in markers]
        self.assertEqual(positions, sorted(positions))
        self.assertIn("the acorn itself is underground", prompt.lower())
        self.assertIn("high_angle_detail", prompt)

    def test_thresholds_require_forbidden_artifacts_to_be_empty(self) -> None:
        pages = storybook.load_storyboard(
            STORYBOOK_DIR / "generation" / "prompts" / "storyboard.yaml"
        )
        evaluation = storybook.evaluation_defaults()
        for key in (
            "character_consistency",
            "style_consistency",
            "story_accuracy",
            "composition_quality",
            "composition_distinctness",
            "environment_scale",
        ):
            evaluation[key] = 5
        passed, failures = storybook.passes_thresholds(pages[2], evaluation)
        self.assertTrue(passed)
        evaluation["forbidden_artifacts"] = ["visible text"]
        passed, failures = storybook.passes_thresholds(pages[2], evaluation)
        self.assertFalse(passed)
        self.assertTrue(any("forbidden_artifacts" in failure for failure in failures))

    def test_run_page_keeps_three_candidates_and_state(self) -> None:
        pages = storybook.load_storyboard(
            STORYBOOK_DIR / "generation" / "prompts" / "storyboard.yaml"
        )
        page = pages[2]
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / "generation" / "prompts").mkdir(parents=True)
            (root / "generation" / "refs").mkdir(parents=True)
            shutil.copyfile(
                STORYBOOK_DIR / "generation" / "prompts" / "storyboard.yaml",
                root / "generation" / "prompts" / "storyboard.yaml",
            )
            context = storybook.RunContext(
                storybook_dir=root,
                dry_run=False,
                quality="medium",
                max_retries=0,
                regenerate=False,
                regenerate_locked=False,
                resume=True,
                client=FakeClient(),
                budget=storybook.CostBudget.from_args(None),
            )
            storybook.load_state(context, pages)
            success, evaluation = storybook.run_page(
                context,
                page,
                pages,
                "canonical style",
                None,
            )
            self.assertTrue(success)
            self.assertEqual(evaluation["recommended_variant"], "c")
            for variant in storybook.VARIANTS:
                self.assertTrue((root / "generation" / "output" / page.id / f"variant_{variant}.png").is_file())
            state = json.loads((root / "generation" / "output" / ".state.json").read_text())
            self.assertEqual(state["pages"][page.id]["status"], "completed")

    def test_similarity_comparison_consumes_one_bounded_revision(self) -> None:
        pages = storybook.load_storyboard(
            STORYBOOK_DIR / "generation" / "prompts" / "storyboard.yaml"
        )
        page = pages[2]
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / "generation" / "prompts").mkdir(parents=True)
            (root / "generation" / "refs").mkdir(parents=True)
            context = storybook.RunContext(
                storybook_dir=root,
                dry_run=False,
                quality="medium",
                max_retries=1,
                regenerate=False,
                regenerate_locked=False,
                resume=True,
                client=SimilarityClient(),
                budget=storybook.CostBudget.from_args(None),
            )
            storybook.load_state(context, pages)
            success, evaluation = storybook.run_page(context, page, pages, "canonical style", None)
            self.assertTrue(success)
            client = context.client
            self.assertEqual(client.responses.comparison_count, 2)
            self.assertEqual(
                context.state["pages"][page.id]["variants"]["a"]["attempt_count"],
                2,
            )


if __name__ == "__main__":
    unittest.main()
