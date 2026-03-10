#!/usr/bin/env python3
"""Generate assets/reference_drawings.json for the DrawBell hint system.

Downloads N recognized Quick Draw examples per category, picks the most
canonical one (moderate stroke count and point density), then saves
normalized stroke data (coordinates in 0-255 range) as a compact JSON asset.

Usage:
    python3 scripts/generate_reference_drawings.py [--categories cat1,cat2,...]

    --categories  Comma-separated list of category names to regenerate.
                  If omitted, all 345 categories are regenerated.
"""

import argparse
import json
import sys
import urllib.request
from pathlib import Path

LABELS_FILE = Path(__file__).parent.parent / "assets" / "labels.txt"
OUTPUT_FILE = Path(__file__).parent.parent / "assets" / "reference_drawings.json"
BASE_URL = "https://storage.googleapis.com/quickdraw_dataset/full/simplified/"

N_CANDIDATES = 20
IDEAL_STROKES = 5
IDEAL_POINTS = 60


def category_to_filename(category: str) -> str:
    return category.replace(" ", "%20") + ".ndjson"


def _candidate_score(drawing: list) -> float:
    n_strokes = len(drawing)
    total_pts = sum(len(s[0]) for s in drawing)
    return abs(n_strokes - IDEAL_STROKES) * 4 + abs(total_pts - IDEAL_POINTS)


def fetch_best_drawing(category: str) -> list | None:
    url = BASE_URL + category_to_filename(category)
    candidates: list[list] = []
    try:
        req = urllib.request.Request(
            url,
            headers={"User-Agent": "DrawBell/1.0"},
        )
        buf = b""
        with urllib.request.urlopen(req, timeout=30) as response:
            while len(candidates) < N_CANDIDATES:
                chunk = response.read(131072)
                if not chunk:
                    break
                buf += chunk
                lines = buf.split(b"\n")
                buf = lines[-1]
                for raw in lines[:-1]:
                    raw = raw.strip()
                    if not raw:
                        continue
                    try:
                        obj = json.loads(raw)
                    except json.JSONDecodeError:
                        continue
                    if not obj.get("recognized", False):
                        continue
                    drawing = obj.get("drawing")
                    if not drawing or len(drawing) < 2:
                        continue
                    candidates.append(drawing)
                    if len(candidates) >= N_CANDIDATES:
                        break
    except Exception as e:
        print(f"  ERROR: {e}", file=sys.stderr)
        return None

    if not candidates:
        return None

    preferred = [
        d for d in candidates
        if 2 <= len(d) <= 10
        and 20 <= sum(len(s[0]) for s in d) <= 130
    ]
    pool = preferred if preferred else candidates
    return min(pool, key=_candidate_score)


def normalize_strokes(drawing: list, target: int = 255) -> list:
    all_x = [x for stroke in drawing for x in stroke[0]]
    all_y = [y for stroke in drawing for y in stroke[1]]

    if not all_x or not all_y:
        return drawing

    min_x, max_x = min(all_x), max(all_x)
    min_y, max_y = min(all_y), max(all_y)
    range_x = max(max_x - min_x, 1)
    range_y = max(max_y - min_y, 1)
    scale = min(target / range_x, target / range_y)
    offset_x = (target - range_x * scale) / 2
    offset_y = (target - range_y * scale) / 2

    normalized = []
    for stroke in drawing:
        xs = [round((x - min_x) * scale + offset_x) for x in stroke[0]]
        ys = [round((y - min_y) * scale + offset_y) for y in stroke[1]]
        normalized.append([xs, ys])

    return normalized


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--categories",
        help="Comma-separated categories to regenerate (default: all)",
    )
    args = parser.parse_args()

    all_labels = LABELS_FILE.read_text(encoding="utf-8").strip().splitlines()

    if args.categories:
        targets = [c.strip() for c in args.categories.split(",")]
        invalid = [c for c in targets if c not in all_labels]
        if invalid:
            print(f"Unknown categories: {invalid}", file=sys.stderr)
            sys.exit(1)
    else:
        targets = all_labels

    existing: dict[str, list] = {}
    if OUTPUT_FILE.exists():
        try:
            existing = json.loads(OUTPUT_FILE.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            pass

    result = dict(existing)

    for i, label in enumerate(targets):
        print(f"[{i + 1:3}/{len(targets)}] {label}...", end=" ", flush=True)
        drawing = fetch_best_drawing(label)
        if drawing:
            n_strokes = len(drawing)
            total_pts = sum(len(s[0]) for s in drawing)
            result[label] = normalize_strokes(drawing)
            print(f"ok ({n_strokes} strokes, {total_pts} pts)")
        else:
            print("FAILED")

    OUTPUT_FILE.write_text(
        json.dumps(result, separators=(",", ":")),
        encoding="utf-8",
    )
    print(f"\nSaved {len(result)}/{len(all_labels)} categories to {OUTPUT_FILE}")


if __name__ == "__main__":
    main()
