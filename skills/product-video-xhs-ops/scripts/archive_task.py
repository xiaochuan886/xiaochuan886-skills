#!/usr/bin/env python3
"""Move a processed task folder from 待完成 into the dated 已落盘 task directory."""

from __future__ import annotations

import argparse
import json
import shutil
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Archive one processed task folder into 已落盘/YYYY-MM-DD/<task>/source-task")
    parser.add_argument("--task-dir", required=True, help="Absolute path to the source task folder under 待完成")
    parser.add_argument("--output-dir", required=True, help="Absolute path to the dated task output directory")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    task_dir = Path(args.task_dir).expanduser().resolve()
    output_dir = Path(args.output_dir).expanduser().resolve()
    if not task_dir.exists():
        raise SystemExit(f"task_dir 不存在: {task_dir}")
    if not output_dir.exists():
        raise SystemExit(f"output_dir 不存在: {output_dir}")

    target = output_dir / "source-task"
    if target.exists():
        raise SystemExit(f"目标目录已存在，拒绝覆盖: {target}")

    shutil.move(str(task_dir), str(target))
    print(json.dumps({
        "moved_from": str(task_dir),
        "moved_to": str(target),
    }, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
