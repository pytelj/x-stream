#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="${OUT_DIR:-results}"
OUT="${OUT_DIR}/diskspeed-2.csv"

DIR="${DIR:-/tmp}"
SIZE="${SIZE:-512M}" 
RUNTIME="${RUNTIME:-15}"
IODEPTH="${IODEPTH:-32}"
NUMJOBS="${NUMJOBS:-1}"

MIN_FREE_GIB="${MIN_FREE_GIB:-10}"

BS_LIST=(4K 8K 16K 32K 64K 128K 256K 512K 1M 2M 4M 8M 16M)

mkdir -p "$OUT_DIR"
echo "pattern,bs,bw_read_kib_s,bw_write_kib_s,iops_read,iops_write,lat_ns_mean_read,lat_ns_mean_write" > "$OUT"

mkdir -p "$DIR"

avail_kib="$(df --output=avail -k "$DIR" | tail -1 | tr -d ' ')"
min_kib="$(( MIN_FREE_GIB * 1024 * 1024 ))"
if (( avail_kib < min_kib )); then
  echo "ERROR: Not enough free space on filesystem for DIR=$DIR" >&2
  echo "Need at least ${MIN_FREE_GIB} GiB free; have $((avail_kib / 1024 / 1024)) GiB." >&2
  exit 1
fi

JOBFILE="${DIR}/fio_xstream_test.dat"

cleanup() {
  rm -f "$JOBFILE" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

run_fio() {
  local pattern="$1" bs="$2"
  local rw extra=()

  case "$pattern" in
    seqread)   rw="read" ;;
    seqwrite)  rw="write" ;;
    randread)  rw="randread" ;;
    randwrite) rw="randwrite" ;;
    mix40)     rw="rw"; extra+=(--rwmixread=40) ;;
    *) echo "unknown pattern: $pattern" >&2; exit 1 ;;
  esac

  fio --name="xstream_${pattern}_${bs}" \
      --directory="$DIR" \
      --filename="$JOBFILE" \
      --size="$SIZE" \
      --runtime="$RUNTIME" --time_based \
      --ioengine=libaio --direct=1 \
      --rw="$rw" --bs="$bs" \
      --iodepth="$IODEPTH" --numjobs="$NUMJOBS" \
      --group_reporting \
      --fallocate=none \
      "${extra[@]}" \
      --output-format=json
}

extract_csv_line() {
  local pattern="$1" bs="$2" json="$3"

  local bw_r bw_w iops_r iops_w lat_r lat_w
  bw_r="$(echo "$json" | jq -r '.jobs[0].read.bw // 0')"
  bw_w="$(echo "$json" | jq -r '.jobs[0].write.bw // 0')"
  iops_r="$(echo "$json" | jq -r '.jobs[0].read.iops // 0')"
  iops_w="$(echo "$json" | jq -r '.jobs[0].write.iops // 0')"
  lat_r="$(echo "$json" | jq -r '.jobs[0].read.lat_ns.mean // 0')"
  lat_w="$(echo "$json" | jq -r '.jobs[0].write.lat_ns.mean // 0')"

  echo "${pattern},${bs},${bw_r},${bw_w},${iops_r},${iops_w},${lat_r},${lat_w}"
}

PATTERNS=(seqread seqwrite randread randwrite mix40)

for bs in "${BS_LIST[@]}"; do
  for pattern in "${PATTERNS[@]}"; do
    echo "Running: ${pattern} bs=${bs}"
    json="$(run_fio "$pattern" "$bs")"
    extract_csv_line "$pattern" "$bs" "$json" >> "$OUT"
    cleanup
  done
done

echo "Wrote: $OUT"
