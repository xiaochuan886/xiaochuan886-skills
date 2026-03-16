#!/usr/bin/env python3
"""Download and concatenate two generated promo video segments."""

import argparse
import shlex
import subprocess
import urllib.request
from pathlib import Path


FFMPEG = Path("/Users/luxiaochuan/Library/Application Support/bilibili/ffmpeg/ffmpeg")


def run(cmd):
    subprocess.run(cmd, check=True)


def download(url: str, path: Path):
    urllib.request.urlretrieve(url, path)


def concat_videos(video_paths, output: Path):
    list_file = output.parent / "video_concat.txt"
    content = "\n".join(f"file {shlex.quote(str(p))}" for p in video_paths)
    list_file.write_text(content, encoding="utf-8")

    run([
        str(FFMPEG), "-y",
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

    if not FFMPEG.exists():
        raise SystemExit(f"未找到 ffmpeg: {FFMPEG}")

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
