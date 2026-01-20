#!/usr/bin/env python3
import argparse
import os
import random
import struct
from typing import Dict, Iterable, Tuple, Optional


COMMENT_PREFIXES_DEFAULT = ("#", "%")


def iter_edges(
    input_path: str,
    *,
    comment_prefixes: Tuple[str, ...] = COMMENT_PREFIXES_DEFAULT,
    delimiter: str | None = None,
) -> Iterable[Tuple[int, int, Optional[float]]]:
    with open(input_path, "r", encoding="utf-8", errors="replace") as fin:
        for line_no, line in enumerate(fin, start=1):
            line = line.strip()
            if not line:
                continue
            if any(line.startswith(p) for p in comment_prefixes):
                continue

            parts = line.split(delimiter) if delimiter is not None else line.split()
            if len(parts) < 2:
                continue

            try:
                u = int(parts[0])
                v = int(parts[1])
            except ValueError:
                continue
            
            if u < 0 or v < 0:
                raise ValueError(f"Negative vertex id at line {line_no}: {u}, {v}")

            w: Optional[float] = None
            if len(parts) >= 3:
                try:
                    w = float(parts[2])
                except ValueError:
                    raise ValueError(f"Invalid weight at line {line_no}: {parts[2]!r}")

            if w is not None and w < 0:
                raise ValueError(f"Negative weight at line {line_no}: {w}")

            yield u, v, w


def build_reindex_map(
    input_path: str,
    *,
    comment_prefixes: Tuple[str, ...],
    delimiter: str | None,
) -> Dict[int, int]:
    nodes = set()
    for u, v, _w in iter_edges(input_path, comment_prefixes=comment_prefixes, delimiter=delimiter):
        nodes.add(u)
        nodes.add(v)

    nodes_sorted = sorted(nodes)
    return {old: new for new, old in enumerate(nodes_sorted)}


def convert_edgelist_to_xstream_type1_compact(
    input_path: str,
    output_path: str,
    *,
    add_rev_edges: bool = False,
    seed: int = 0,
    comment_prefixes: Tuple[str, ...] = COMMENT_PREFIXES_DEFAULT,
    delimiter: str | None = None,
    reindex: bool = False,
) -> Tuple[int, int]:
    random.seed(seed)

    packer = struct.Struct("@IIf")

    id_map: Dict[int, int] | None = None
    if reindex:
        print("Pass 1/2: building dense ID mapping...")
        id_map = build_reindex_map(
            input_path, comment_prefixes=comment_prefixes, delimiter=delimiter
        )
        print(f"  mapped vertices = {len(id_map)}")

    print("Pass 2/2: writing binary + .ini...")
    edges_written = 0
    max_vid = -1

    with open(output_path, "wb") as fout:
        for u, v, w_in in iter_edges(input_path, comment_prefixes=comment_prefixes, delimiter=delimiter):
            if id_map is not None:
                u2 = id_map[u]
                v2 = id_map[v]
            else:
                u2, v2 = u, v

            w = float(w_in) if w_in is not None else random.random()

            fout.write(packer.pack(u2, v2, w))
            edges_written += 1

            if add_rev_edges and u2 != v2:
                fout.write(packer.pack(v2, u2, w))
                edges_written += 1

            if id_map is None:
                if u2 > max_vid:
                    max_vid = u2
                if v2 > max_vid:
                    max_vid = v2

    vertices = len(id_map) if id_map is not None else ((max_vid + 1) if max_vid >= 0 else 0)

    ini_path = output_path + ".ini"
    with open(ini_path, "w", encoding="utf-8") as meta:
        meta.write("[graph]\n")
        meta.write("type=1\n")
        meta.write(f"name={os.path.basename(output_path)}\n")
        meta.write(f"vertices={vertices}\n")
        meta.write(f"edges={edges_written}\n")

    return vertices, edges_written


def main():
    ap = argparse.ArgumentParser(
        description="Convert a text edge list to X-Stream type=1 COMPACT (binary + .ini)."
    )
    ap.add_argument("input", help="Path to input edge list text file.")
    ap.add_argument("output", help="Output binary filename.")
    ap.add_argument("--add-rev-edges", action="store_true",
                    help="Also write reverse edges (dst,src) for each (src,dst).")
    ap.add_argument("--seed", type=int, default=0,
                    help="RNG seed for deterministic random weights (default: 0).")
    ap.add_argument("--delimiter", default=None,
                    help="Delimiter (default: any whitespace).")
    ap.add_argument("--reindex", action="store_true",
                    help="Remap arbitrary node IDs to dense 0..V-1.")

    args = ap.parse_args()

    delim = args.delimiter.encode("utf-8").decode("unicode_escape") if args.delimiter else None

    v, e = convert_edgelist_to_xstream_type1_compact(
        args.input,
        args.output,
        add_rev_edges=args.add_rev_edges,
        seed=args.seed,
        delimiter=delim,
        reindex=args.reindex,
    )

    bin_size = os.path.getsize(args.output)
    expected = e * 12  # 12 bytes per edge
    print("Done.")
    print(f"  Binary: {args.output} ({bin_size} bytes)")
    print(f"  INI:    {args.output}.ini")
    print(f"  vertices={v}, edges={e}")
    print(f"  sanity: expected_size={expected} bytes ({'OK' if expected == bin_size else 'MISMATCH'})")


if __name__ == "__main__":
    main()
