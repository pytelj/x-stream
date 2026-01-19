#!/usr/bin/env bash
set -euo pipefail

SLEEP=10

RUN_IDS=(0 1 2)

commands=(
"sudo ./bin/benchmark_driver -g amazon0601-sym -b cc -p 16 -a --physical_memory 8589934592 --measure_scatter_gather > logs/runs/exp1/amazon0601-wcc-r%s.log 2>&1"
"sudo ./bin/benchmark_driver -g amazon0601-dir -b scc -p 16 -a --physical_memory 8589934592 --measure_scatter_gather > logs/runs/exp1/amazon0601-scc-r%s.log 2>&1"
"sudo ./bin/benchmark_driver -g amazon0601-dir -b sssp -p 16 -a --physical_memory 8589934592 --measure_scatter_gather > logs/runs/exp1/amazon0601-sssp-r%s.log 2>&1"
"sudo ./bin/benchmark_driver -g amazon0601-sym -b mcst -p 16 -a --physical_memory 8589934592 --measure_scatter_gather > logs/runs/exp1/amazon0601-mcst-r%s.log 2>&1"
"sudo ./bin/benchmark_driver -g amazon0601-sym -b mis -p 16 -a --physical_memory 8589934592 --measure_scatter_gather > logs/runs/exp1/amazon0601-mis-r%s.log 2>&1"
"sudo ./bin/benchmark_driver -g amazon0601-sym -b conductance -p 16 -a --physical_memory 8589934592 --measure_scatter_gather > logs/runs/exp1/amazon0601-cond-r%s.log 2>&1"
"sudo ./bin/benchmark_driver -g amazon0601-dir -b spmv -p 16 -a --physical_memory 8589934592 --measure_scatter_gather > logs/runs/exp1/amazon0601-spmv-r%s.log 2>&1"
"sudo ./bin/benchmark_driver -g amazon0601-dir -b pagerank --pagerank::niters 20 -p 16 -a --physical_memory 8589934592 --measure_scatter_gather > logs/runs/exp1/amazon0601-pagerank-r%s.log 2>&1"
"sudo ./bin/benchmark_driver -g cit-Patents-sym -b cc -p 16 -a --physical_memory 8589934592 --measure_scatter_gather > logs/runs/exp1/cit-Patents-wcc-r%s.log 2>&1"
"sudo ./bin/benchmark_driver -g cit-Patents-dir -b scc -p 16 -a --physical_memory 8589934592 --measure_scatter_gather > logs/runs/exp1/cit-Patents-scc-r%s.log 2>&1"
"sudo ./bin/benchmark_driver -g cit-Patents-dir -b sssp -p 16 -a --physical_memory 8589934592 --measure_scatter_gather > logs/runs/exp1/cit-Patents-sssp-r%s.log 2>&1"
"sudo ./bin/benchmark_driver -g cit-Patents-sym -b mcst -p 16 -a --physical_memory 8589934592 --measure_scatter_gather > logs/runs/exp1/cit-Patents-mcst-r%s.log 2>&1"
"sudo ./bin/benchmark_driver -g cit-Patents-sym -b mis -p 16 -a --physical_memory 8589934592 --measure_scatter_gather > logs/runs/exp1/cit-Patents-mis-r%s.log 2>&1"
"sudo ./bin/benchmark_driver -g cit-Patents-sym -b conductance -p 16 -a --physical_memory 8589934592 --measure_scatter_gather > logs/runs/exp1/cit-Patents-cond-r%s.log 2>&1"
"sudo ./bin/benchmark_driver -g cit-Patents-dir -b spmv -p 16 -a --physical_memory 8589934592 --measure_scatter_gather > logs/runs/exp1/cit-Patents-spmv-r%s.log 2>&1"
"sudo ./bin/benchmark_driver -g cit-Patents-dir -b pagerank --pagerank::niters 20 -p 16 -a --physical_memory 8589934592 --measure_scatter_gather > logs/runs/exp1/cit-Patents-pagerank-r%s.log 2>&1"
"sudo ./bin/benchmark_driver -g soc-LiveJournal1-sym -b cc -p 16 -a --physical_memory 8589934592 --measure_scatter_gather > logs/runs/exp1/soc-LiveJournal1-wcc-r%s.log 2>&1"
"sudo ./bin/benchmark_driver -g soc-LiveJournal1-dir -b scc -p 16 -a --physical_memory 8589934592 --measure_scatter_gather > logs/runs/exp1/soc-LiveJournal1-scc-r%s.log 2>&1"
"sudo ./bin/benchmark_driver -g soc-LiveJournal1-dir -b sssp -p 16 -a --physical_memory 8589934592 --measure_scatter_gather > logs/runs/exp1/soc-LiveJournal1-sssp-r%s.log 2>&1"
"sudo ./bin/benchmark_driver -g soc-LiveJournal1-sym -b mcst -p 16 -a --physical_memory 8589934592 --measure_scatter_gather > logs/runs/exp1/soc-LiveJournal1-mcst-r%s.log 2>&1"
"sudo ./bin/benchmark_driver -g soc-LiveJournal1-sym -b mis -p 16 -a --physical_memory 8589934592 --measure_scatter_gather > logs/runs/exp1/soc-LiveJournal1-mis-r%s.log 2>&1"
"sudo ./bin/benchmark_driver -g soc-LiveJournal1-sym -b conductance -p 16 -a --physical_memory 8589934592 --measure_scatter_gather > logs/runs/exp1/soc-LiveJournal1-cond-r%s.log 2>&1"
"sudo ./bin/benchmark_driver -g soc-LiveJournal1-dir -b spmv -p 16 -a --physical_memory 8589934592 --measure_scatter_gather > logs/runs/exp1/soc-LiveJournal1-spmv-r%s.log 2>&1"
"sudo ./bin/benchmark_driver -g soc-LiveJournal1-dir -b pagerank --pagerank::niters 20 -p 16 -a --physical_memory 8589934592 --measure_scatter_gather > logs/runs/exp1/soc-LiveJournal1-pagerank-r%s.log 2>&1"
"sudo ./bin/benchmark_driver -g dimacs-usa-sym -b cc -p 16 -a --physical_memory 8589934592 --measure_scatter_gather > logs/runs/exp1/dimacs-usa-wcc-r%s.log 2>&1"
# "sudo ./bin/benchmark_driver -g dimacs-usa-dir -b scc -p 16 -a --physical_memory 8589934592 --measure_scatter_gather > logs/runs/exp1/dimacs-usa-scc-r%s.log 2>&1"  # takes too long to complete
# "sudo ./bin/benchmark_driver -g dimacs-usa-dir -b sssp -p 16 -a --physical_memory 8589934592 --measure_scatter_gather > logs/runs/exp1/dimacs-usa-sssp-r%s.log 2>&1"  # takes too long to complete
"sudo ./bin/benchmark_driver -g dimacs-usa-sym -b mcst -p 16 -a --physical_memory 8589934592 --measure_scatter_gather > logs/runs/exp1/dimacs-usa-mcst-r%s.log 2>&1"
"sudo ./bin/benchmark_driver -g dimacs-usa-sym -b mis -p 16 -a --physical_memory 8589934592 --measure_scatter_gather > logs/runs/exp1/dimacs-usa-mis-r%s.log 2>&1"
"sudo ./bin/benchmark_driver -g dimacs-usa-sym -b conductance -p 16 -a --physical_memory 8589934592 --measure_scatter_gather > logs/runs/exp1/dimacs-usa-cond-r%s.log 2>&1"
"sudo ./bin/benchmark_driver -g dimacs-usa-dir -b spmv -p 16 -a --physical_memory 8589934592 --measure_scatter_gather > logs/runs/exp1/dimacs-usa-spmv-r%s.log 2>&1"
"sudo ./bin/benchmark_driver -g dimacs-usa-dir -b pagerank --pagerank::niters 20 -p 16 -a --physical_memory 8589934592 --measure_scatter_gather > logs/runs/exp1/dimacs-usa-pagerank-r%s.log 2>&1"
)

for RUN_ID in "${RUN_IDS[@]}"; do
  for tmpl in "${commands[@]}"; do
    cmd=$(printf "$tmpl" "$RUN_ID")

    echo "=== Sleeping ${SLEEP}s ==="
    sleep "$SLEEP"
    echo "=== Running (run=${RUN_ID}): $cmd ==="
    eval "$cmd"
    echo "=== Done (run=${RUN_ID}) ==="
  done
done
