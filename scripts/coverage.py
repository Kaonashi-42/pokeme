#!/usr/bin/env python3
"""Line coverage of one source directory, from the JSON written by `swift test --enable-code-coverage`.

Usage: coverage.py <codecov.json> <source dir> [--badge <out.json>]

Prints a per-file table and the total. With --badge, also writes a shields.io endpoint file for the README badge.
In GitHub Actions the table is added to the job summary too.
"""

import argparse
import json
import os
import sys


def badge_color(percent):
    for threshold, color in [(90, "brightgreen"), (80, "green"), (70, "yellowgreen"), (60, "yellow"), (50, "orange")]:
        if percent >= threshold:
            return color
    return "red"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("report")
    parser.add_argument("source_dir")
    parser.add_argument("--badge")
    args = parser.parse_args()

    root = os.path.abspath(args.source_dir) + os.sep
    with open(args.report) as report:
        files = json.load(report)["data"][0]["files"]
    rows = [
        (os.path.relpath(f["filename"]), f["summary"]["lines"]["covered"], f["summary"]["lines"]["count"])
        for f in files
        if f["filename"].startswith(root)
    ]
    if not rows:
        sys.exit(f"No coverage data for {args.source_dir}")

    covered = sum(row[1] for row in rows)
    total = sum(row[2] for row in rows)
    percent = 100 * covered / total
    lines = ["| File | Lines | Coverage |", "| --- | ---: | ---: |"]
    lines += [f"| {name} | {hit}/{count} | {100 * hit / count:.1f}% |" for name, hit, count in sorted(rows)]
    lines.append(f"| **Total** | **{covered}/{total}** | **{percent:.1f}%** |")
    table = "\n".join(lines)
    print(table)

    if summary := os.environ.get("GITHUB_STEP_SUMMARY"):
        with open(summary, "a") as out:
            out.write(f"## Coverage of {args.source_dir}\n\n{table}\n")
    if args.badge:
        with open(args.badge, "w") as out:
            json.dump(
                {"schemaVersion": 1, "label": "coverage", "message": f"{percent:.0f}%", "color": badge_color(percent)},
                out,
            )


if __name__ == "__main__":
    main()
