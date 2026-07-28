#!/usr/bin/env python3
"""Evaluate a battery telemetry log against the REQ-BAT requirements.

Reads a log written by collect_battery_log.py and prints one verdict line
per requirement ID, so that the output can be pasted into the TAE note as
evidence without a human re-deriving which line proves what.

The operating range below realizes the contract declared in
IFC_PWR_DC_LiPo_Pack. Change it there first, then here.

Stdlib only, matching the vault validator.

Exit codes: 0 = every requirement passed, 1 = at least one failed,
2 = the log could not be read.

Usage:
    eval_battery_log.py <log.csv>
"""

import csv
import sys
from pathlib import Path

# IFC_PWR_DC_LiPo_Pack operating range, in volts.
CONTRACT_V_MIN = 12.00
CONTRACT_V_MAX = 17.40

# REQ-BAT-001 allows a sample gap of at most this multiple of nominal.
MAX_GAP_FACTOR = 2.0


def read_log(path):
    """-> (header dict from '#' lines, list of data rows)."""
    header, data_lines = {}, []
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.startswith("#"):
            key, _, value = line[1:].partition(":")
            header[key.strip()] = value.strip()
        else:
            data_lines.append(line)
    return header, list(csv.DictReader(data_lines))


def check_sample_gap(header, rows):
    """REQ-BAT-001 - no gap between consecutive samples above the limit."""
    try:
        nominal = float(header["nominal_interval_s"])
    except (KeyError, ValueError):
        return False, "log header carries no usable nominal_interval_s"
    if len(rows) < 2:
        return False, f"{len(rows)} sample(s) - a gap needs at least two"
    limit = nominal * MAX_GAP_FACTOR
    try:
        times = [float(r["t_rel_s"]) for r in rows]
    except (KeyError, ValueError):
        return False, "column t_rel_s missing or not numeric"
    gaps = [b - a for a, b in zip(times, times[1:])]
    worst = max(gaps)
    return (worst <= limit,
            f"max sample gap {worst:.3f} s, limit {limit:.3f} s "
            f"({MAX_GAP_FACTOR:g} x nominal {nominal:g} s)")


def check_voltage_range(rows):
    """REQ-BAT-002 - every recorded voltage inside the interface contract."""
    try:
        volts = [float(r["voltage_v"]) for r in rows]
    except (KeyError, ValueError):
        return False, "column voltage_v missing or not numeric"
    if not volts:
        return False, "log contains no samples"
    low, high = min(volts), max(volts)
    return (CONTRACT_V_MIN <= low and high <= CONTRACT_V_MAX,
            f"recorded {low:.3f} .. {high:.3f} V, contract "
            f"{CONTRACT_V_MIN:.2f} .. {CONTRACT_V_MAX:.2f} V")


def check_identification(header):
    """REQ-BAT-003 - the log names the pack it was recorded from."""
    manufacturer = header.get("manufacturer", "")
    model = header.get("model_name", "")
    if manufacturer and model:
        return True, f"pack identification present: {manufacturer} / {model}"
    missing = [n for n, v in (("manufacturer", manufacturer),
                              ("model_name", model)) if not v]
    return False, "missing pack identification: " + ", ".join(missing)


def main(argv):
    if len(argv) != 1:
        print(__doc__.strip().splitlines()[-1], file=sys.stderr)
        return 2
    path = Path(argv[0])
    try:
        header, rows = read_log(path)
    except OSError as exc:
        print(f"cannot read {path}: {exc}", file=sys.stderr)
        return 2

    print(f"log: {path}")
    print(f"samples: {len(rows)}")
    results = [
        ("REQ-BAT-001", *check_sample_gap(header, rows)),
        ("REQ-BAT-002", *check_voltage_range(rows)),
        ("REQ-BAT-003", *check_identification(header)),
    ]
    for req_id, passed, detail in results:
        print(f"{req_id}  {'PASS' if passed else 'FAIL'}  {detail}")
    passed_n = sum(1 for _, ok, _ in results if ok)
    total = len(results)
    verdict = "PASS" if passed_n == total else "FAIL"
    print(f"VERDICT: {verdict} ({passed_n}/{total})")
    return 0 if passed_n == total else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
