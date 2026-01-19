#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="${OUT_DIR:-results/ssd_seq_vs_rand}"
DIR="${DIR:-/mnt/bench}"
FILE="${FILE:-fio_test.dat}"

SIZE="${SIZE:-2G}"
RUNTIME="${RUNTIME:-15}"
BS="${BS:-4K}"
IODEPTH="${IODEPTH:-1}"
NUMJOBS="${NUMJOBS:-1}"

MIN_FREE_GIB="${MIN_FREE_GIB:-10}"

mkdir -p "$OUT_DIR"
mkdir -p "$DIR"

avail_kib="$(df --output=avail -k "$DIR" | tail -1 | tr -d ' ')"
min_kib="$(( MIN_FREE_GIB * 1024 * 1024 ))"
if (( avail_kib < min_kib )); then
  echo "ERROR: Less than ${MIN_FREE_GIB} GiB free on filesystem backing $DIR"
  exit 1
fi

JOBFILE="${FILE}"

cleanup() {
  rm -f "$JOBFILE" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

CSV="${OUT_DIR}/ssd_seq_vs_rand.csv"
echo "pattern,bs,bw_read_MB_s,bw_write_MB_s,iops_read,iops_write,lat_read_ns,lat_write_ns" > "$CSV"

run_fio() {
  local name="$1" rw="$2"
  local extra=()

  fio --name="$name" \
      --directory="$DIR" \
      --filename="$JOBFILE" \
      --size="$SIZE" \
      --runtime="$RUNTIME" --time_based \
      --ioengine=libaio --direct=1 \
      --rw="$rw" --bs="$BS" \
      --iodepth="$IODEPTH" --numjobs="$NUMJOBS" \
      --group_reporting \
      --fallocate=none \
      "${extra[@]}" \
      --output-format=json
}

extract_csv() {
  local pattern="$1" json="$2"

  local bw_r bw_w iops_r iops_w lat_r lat_w
  bw_r="$(echo "$json" | jq -r '.jobs[0].read.bw // 0')"   # KiB/s
  bw_w="$(echo "$json" | jq -r '.jobs[0].write.bw // 0')"
  iops_r="$(echo "$json" | jq -r '.jobs[0].read.iops // 0')"
  iops_w="$(echo "$json" | jq -r '.jobs[0].write.iops // 0')"
  lat_r="$(echo "$json" | jq -r '.jobs[0].read.lat_ns.mean // 0')"
  lat_w="$(echo "$json" | jq -r '.jobs[0].write.lat_ns.mean // 0')"

  # Convert KiB/s to MB/s
  bw_r="$(awk "BEGIN { printf \"%.2f\", $bw_r / 1024 }")"
  bw_w="$(awk "BEGIN { printf \"%.2f\", $bw_w / 1024 }")"

  echo "${pattern},${BS},${bw_r},${bw_w},${iops_r},${iops_w},${lat_r},${lat_w}" >> "$CSV"
}

echo "Running SSD sequential vs random"

echo "seqread"
json="$(run_fio seqread read)"
echo "$json" > "${OUT_DIR}/seqread.json"
extract_csv seqread "$json"

echo "randread"
json="$(run_fio randread randread)"
echo "$json" > "${OUT_DIR}/randread.json"
extract_csv randread "$json"

echo "seqwrite"
json="$(run_fio seqwrite write)"
echo "$json" > "${OUT_DIR}/seqwrite.json"
extract_csv seqwrite "$json"

echo "randwrite"
json="$(run_fio randwrite randwrite)"
echo "$json" > "${OUT_DIR}/randwrite.json"
extract_csv randwrite "$json"

echo
echo "Done."
echo "Results:"
echo "  CSV : $CSV"
echo "  JSON: $OUT_DIR/*.json"
