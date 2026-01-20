#!/usr/bin/env python3
from __future__ import annotations

import argparse
from pathlib import Path


def convert_line(line: str, lineno: int) -> str:
    stripped = line.rstrip("\n")

    if stripped == "":
        return ""

    parts = stripped.split()
    assert len(parts) >= 1, f"Line {lineno}: unexpected empty tokenization"

    first = parts[0]
    assert len(first) == 1, (
        f"Line {lineno}: expected first token to be a single character, got {first!r}"
    )

    if first == "a":
        return " ".join(parts[1:])
    else:
        parts[0] = "#"
        return " ".join(parts)


def convert_file(inp: Path, out: Path) -> None:
    with inp.open("r", encoding="utf-8", errors="replace") as fin, out.open(
        "w", encoding="utf-8"
    ) as fout:
        for lineno, line in enumerate(fin, start=1):
            converted = convert_line(line, lineno)
            fout.write(converted + "\n")


def main() -> None:
    parser = argparse.ArgumentParser(description="Convert .gr to .txt with custom rules.")
    parser.add_argument("input", type=Path, help="Input .gr file path")
    parser.add_argument("output", type=Path, help="Output .txt file path")
    args = parser.parse_args()

    if not args.input.exists():
        raise FileNotFoundError(f"Input file not found: {args.input}")

    convert_file(args.input, args.output)


if __name__ == "__main__":
    main()
