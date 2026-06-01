def merge_ranges(intervals):
    """Return sorted intervals with overlaps and touching ranges merged."""
    if not intervals:
        return []

    merged = []
    for start, end in intervals:
        if merged and start <= merged[-1][1]:
            merged[-1][1] = max(merged[-1][1], end)
        else:
            merged.append([start, end])
    return merged
