#!/usr/bin/env python3
"""Validate deterministic structure for a generated 2-segment campaign."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Validate a product campaign report and required files.")
    parser.add_argument("--report", required=True, help="Absolute path to campaign-report.json")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    report_path = Path(args.report).expanduser().resolve()
    if not report_path.exists():
        raise SystemExit(f"campaign-report.json 不存在: {report_path}")

    report = json.loads(report_path.read_text(encoding="utf-8"))
    errors: list[str] = []

    if not str(report.get("segment_1_url", "")).strip():
        errors.append("缺少 segment_1_url")
    if not str(report.get("segment_2_url", "")).strip():
        errors.append("缺少 segment_2_url")

    final_video = Path(str(report.get("final_video", ""))).expanduser()
    if not final_video.exists():
        errors.append(f"final_video 不存在: {final_video}")

    keyframes = report.get("keyframes", {}) or {}
    for key in ["seg1_start", "seg1_end", "seg2_start", "seg2_end"]:
        candidate = Path(str(keyframes.get(key, ""))).expanduser()
        if not candidate.exists():
            errors.append(f"关键帧缺失: {key} -> {candidate}")

    result = {
        "report": str(report_path),
        "ok": not errors,
        "errors": errors,
    }
    print(json.dumps(result, ensure_ascii=False, indent=2))
    sys.exit(0 if not errors else 1)


if __name__ == "__main__":
    main()
