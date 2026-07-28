#!/usr/bin/env python3
"""Sample the battery pack telemetry into a CSV log.

Reads the power-supply class exported by the Linux kernel and writes one
row per sample. The pack is discovered by its reported type, never by a
device index: the enumeration order of /sys/class/power_supply differs
between machines and between boots, so an index would silently sample a
different device elsewhere.

The log carries the pack identification in '#' header lines so that the
evaluation can check it without opening the device again, and so that a
log stays interpretable after the machine that produced it is gone.

Stdlib only, matching the vault validator.

Usage:
    collect_battery_log.py --output <path> [--count N] [--interval S]
"""

import argparse
import csv
import sys
import time
from pathlib import Path

PSU_ROOT = Path("/sys/class/power_supply")

# Identification fields copied into the log header. Serial numbers are
# deliberately absent: the log is committed to a public template repo.
ID_FIELDS = ("manufacturer", "model_name", "technology", "voltage_min_design")

COLUMNS = ("sample_index", "t_rel_s", "voltage_v", "energy_wh", "capacity_pct", "status")


def read_attr(device, name):
    try:
        return (device / name).read_text().strip()
    except OSError:
        return ""


def find_battery():
    """First power-supply device reporting type 'Battery'."""
    if not PSU_ROOT.is_dir():
        return None
    for device in sorted(PSU_ROOT.iterdir()):
        if read_attr(device, "type") == "Battery":
            return device
    return None


def sample(device, index, t_zero):
    """One telemetry row. Microvolt/microwatt-hour values become V and Wh."""
    def micro(name):
        raw = read_attr(device, name)
        return round(int(raw) / 1_000_000, 6) if raw.lstrip("-").isdigit() else ""

    return {
        "sample_index": index,
        "t_rel_s": round(time.monotonic() - t_zero, 6),
        "voltage_v": micro("voltage_now"),
        "energy_wh": micro("energy_now"),
        "capacity_pct": read_attr(device, "capacity"),
        "status": read_attr(device, "status"),
    }


def main(argv):
    ap = argparse.ArgumentParser(description="sample battery telemetry into a CSV log")
    ap.add_argument("--output", required=True, help="path of the CSV log to write")
    ap.add_argument("--count", type=int, default=20, help="number of samples")
    ap.add_argument("--interval", type=float, default=0.25,
                    help="nominal interval between samples in seconds")
    args = ap.parse_args(argv)

    device = find_battery()
    if device is None:
        print("no power-supply device of type 'Battery' found", file=sys.stderr)
        return 2

    out = Path(args.output)
    out.parent.mkdir(parents=True, exist_ok=True)

    t_zero = time.monotonic()
    rows = []
    for index in range(args.count):
        rows.append(sample(device, index, t_zero))
        if index + 1 < args.count:
            time.sleep(args.interval)

    with out.open("w", newline="", encoding="utf-8") as fh:
        fh.write(f"# device: {device.name}\n")
        for field in ID_FIELDS:
            fh.write(f"# {field}: {read_attr(device, field)}\n")
        fh.write(f"# nominal_interval_s: {args.interval}\n")
        fh.write(f"# sample_count: {args.count}\n")
        writer = csv.DictWriter(fh, fieldnames=COLUMNS)
        writer.writeheader()
        writer.writerows(rows)

    print(f"wrote {len(rows)} samples to {out}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
