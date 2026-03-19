#!/usr/bin/env python3
"""Download and concatenate two generated promo video segments."""

import argparse
import os
import shlex
import shutil
import subprocess
import urllib.request
from pathlib import Path


DEFAULT_FFMPEG = Path.home() / "Library" / "Application Support" / "bilibili" / "ffmpeg" / "ffmpeg"


def resolve_ffmpeg() -> str:
    override = os.environ.get("FFMPEG_BIN", "").strip()
    if override:
        return override
    ffmpeg_from_path = shutil.which("ffmpeg")
    if ffmpeg_from_path:
        return ffmpeg_from_path
    if DEFAULT_FFMPEG.exists():
        return str(DEFAULT_FFMPEG)
    raise SystemExit(
        "未找到 ffmpeg。请安装 ffmpeg 到 PATH，或设置 FFMPEG_BIN 指向可执行文件。"
    )


def run(cmd):
    subprocess.run(cmd, check=True)


def download(url: str, path: Path):
    urllib.request.urlretrieve(url, path)


def concat_videos(video_paths, output: Path):
    ffmpeg_bin = resolve_ffmpeg()
    list_file = output.parent / "video_concat.txt"
    content = "\n".join(f"file {shlex.quote(str(p))}" for p in video_paths)
    list_file.write_text(content, encoding="utf-8")

    run([
        ffmpeg_bin, "-y",
        "-f", "concat", "-safe", "0",
        "-i", str(list_file),
        "-c", "copy",
        str(output),
    ])


def main():
    parser = argparse.ArgumentParser(description="Download and concatenate two generated promo video segments.")
    parser.add_argument("--video-url-1", required=True)
    parser.add_argument("--video-url-2", required=True)
    parser.add_argument("--out-dir", required=True)
    parser.add_argument("--output-name", default="final-campaign.mp4")
    args = parser.parse_args()

    out_dir = Path(args.out_dir).resolve()
    out_dir.mkdir(parents=True, exist_ok=True)

    video1 = out_dir / "segment-1.mp4"
    video2 = out_dir / "segment-2.mp4"
    output = out_dir / args.output_name

    download(args.video_url_1, video1)
    download(args.video_url_2, video2)
    concat_videos([video1, video2], output)

    print("Concatenation complete")
    print(f"Final video: {output}")


if __name__ == "__main__":
    main()
