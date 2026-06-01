import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parents[1] / "src"))

from ranges import merge_ranges


class MergeRangesTests(unittest.TestCase):
    def test_sorts_and_merges_overlapping_ranges(self):
        self.assertEqual(merge_ranges([[5, 8], [1, 3], [2, 6]]), [[1, 8]])

    def test_merges_directly_touching_ranges(self):
        self.assertEqual(merge_ranges([[1, 2], [3, 4], [8, 9]]), [[1, 4], [8, 9]])

    def test_does_not_mutate_input(self):
        intervals = [[5, 8], [1, 3]]
        merge_ranges(intervals)
        self.assertEqual(intervals, [[5, 8], [1, 3]])

    def test_empty_input(self):
        self.assertEqual(merge_ranges([]), [])

    def test_rejects_invalid_range(self):
        with self.assertRaises(ValueError):
            merge_ranges([[4, 1]])

    def test_rejects_invalid_shape(self):
        with self.assertRaises(ValueError):
            merge_ranges([[1, 2, 3]])


if __name__ == "__main__":
    unittest.main()
