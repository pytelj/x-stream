#!/usr/bin/env bash
set -euo pipefail

BIN="${BIN:-../x-stream/bin}"
OUT_DIR="${OUT_DIR:-results}"
OUT="${OUT_DIR}/memspeed.csv"

THREADS_LIST=(${THREADS_LIST:-1 2 4 8})
CHUNK_SIZES=(${CHUNK_SIZES:-8})
REPS=${REPS:-5}

mkdir -p "$OUT_DIR"
echo "pattern,chunk_size,threads,rep,memread_mb_s,memwrite_mb_s,memcpy_mb_s" > "$OUT"

run_one() {
  local pattern="$1" chunk="$2" threads="$3"
  local exe
  [[ "$pattern" == "sequential" ]] && exe="${BIN}/mem_speed_sequential" || exe="${BIN}/mem_speed_random"

  local dump
  dump="$(numactl --interleave=all "$exe" "$chunk" "$threads" 2>&1)"

  local memread memwrite memcpy
  memread="$(echo "$dump"  | awk '/MEMREAD/  {val=$NF} END{print val}')"
  memwrite="$(echo "$dump" | awk '/MEMWRITE/ {val=$NF} END{print val}')"
  memcpy="$(echo "$dump"   | awk '/MEMCPY/   {val=$NF} END{print val}')"

  if [[ -z "${memread}" || -z "${memwrite}" || -z "${memcpy}" ]]; then
    echo "ERROR: parse failed for ${pattern} chunk=${chunk} threads=${threads}" >&2
    echo "$dump" >&2
    return 1
  fi

  echo "${memread},${memwrite},${memcpy}"
}

for chunk in "${CHUNK_SIZES[@]}"; do
  for threads in "${THREADS_LIST[@]}"; do
    for pattern in sequential random; do
      for rep in $(seq 1 "$REPS"); do
        IFS=',' read -r memread memwrite memcpy < <(run_one "$pattern" "$chunk" "$threads")
        echo "${pattern},${chunk},${threads},${rep},${memread},${memwrite},${memcpy}" >> "$OUT"
      done
    done
  done
done

echo "Wrote: $OUT"
