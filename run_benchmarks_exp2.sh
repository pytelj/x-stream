#!/usr/bin/env bash
set -euo pipefail

SLEEP=10
RUN_IDS=(0 1 2)

MEM_LABELS=(8g 4g 2g 1g 512m 256m 128m 64m)
MEM_BYTES=(8589934592 4294967296 2147483648 1073741824 536870912 268435456 134217728 67108864)

commands=(
  "sudo ./bin/benchmark_driver -g soc-LiveJournal1-sym -b cc -p 16 -a --physical_memory %s --measure_scatter_gather > logs/runs/exp2/soc-LiveJournal1-wcc-mem%s-r%s.log 2>&1"
  "sudo ./bin/benchmark_driver -g soc-LiveJournal1-dir -b pagerank --pagerank::niters 20 -p 16 -a --physical_memory %s --measure_scatter_gather > logs/runs/exp2/soc-LiveJournal1-pagerank-mem%s-r%s.log 2>&1"
  "sudo ./bin/benchmark_driver -g soc-LiveJournal1-dir -b spmv -p 16 -a --physical_memory %s --measure_scatter_gather > logs/runs/exp2/soc-LiveJournal1-spmv-mem%s-r%s.log 2>&1"
)

for RUN_ID in "${RUN_IDS[@]}"; do
  for i in "${!MEM_BYTES[@]}"; do
    mem_bytes="${MEM_BYTES[$i]}"
    mem_label="${MEM_LABELS[$i]}"

    for tmpl in "${commands[@]}"; do
      cmd=$(printf "$tmpl" "$mem_bytes" "$mem_label" "$RUN_ID")

      echo "=== Sleeping ${SLEEP}s ==="
      sleep "$SLEEP"

      echo "=== Running (run=${RUN_ID}, mem=${mem_label}): $cmd ==="
      eval "$cmd"
      echo "=== Done (run=${RUN_ID}, mem=${mem_label}) ==="
    
      echo "=== Cleaning X-Stream temporary files ==="
      sudo rm -f edges messages* unknown_edges updates* tree_edges vertices*
    done
  done
done
