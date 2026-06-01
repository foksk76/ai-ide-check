import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parents[1] / "src"))

from tag_tools import normalize_tags


class NormalizeTagsTests(unittest.TestCase):
    def test_normalizes_and_deduplicates_in_first_seen_order(self):
        self.assertEqual(
            normalize_tags([" Python ", "OLLAMA", "python", "", "  Git  "]),
            ["python", "ollama", "git"],
        )

    def test_empty_input(self):
        self.assertEqual(normalize_tags([]), [])

    def test_rejects_non_list_input(self):
        with self.assertRaises(TypeError):
            normalize_tags(("python",))

    def test_rejects_non_string_item(self):
        with self.assertRaises(TypeError):
            normalize_tags(["python", 3])


if __name__ == "__main__":
    unittest.main()
