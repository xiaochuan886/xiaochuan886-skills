#!/usr/bin/env python3
"""Generate a product promo video end-to-end with Seedance."""

import argparse
import base64
import os
import sys
import time
from pathlib import Path

try:
    from volcenginesdkarkruntime import Ark
except ImportError:
    print("错误: 请先安装 volcengine-python-sdk")
    print("运行: pip install volcengine-python-sdk")
    sys.exit(1)


SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

from build_prompt import build_marketing_brief, build_prompt, infer_category  # noqa: E402


def load_env_files():
    """Load .env from the skill directory first, then workspace fallbacks."""
    candidates = [
        SCRIPT_DIR.parent / ".env",
        Path("/Users/luxiaochuan/fuxingdaoOPC/coze-video-gen-skill/.env"),
    ]

    for env_path in candidates:
        if not env_path.exists():
            continue

        with open(env_path, "r", encoding="utf-8") as f:
            for raw_line in f:
                line = raw_line.strip()
                if not line or line.startswith("#") or "=" not in line:
                    continue
                key, value = line.split("=", 1)
                key = key.strip()
                value = value.strip().strip('"').strip("'")
                if key and key not in os.environ:
                    os.environ[key] = value


def image_to_data_url(image_path: str) -> str:
    path = Path(image_path).expanduser().resolve()
    if not path.exists():
        print(f"错误: 图片文件不存在: {image_path}")
        sys.exit(1)

    suffix = path.suffix.lower()
    mime = {
        ".jpg": "image/jpeg",
        ".jpeg": "image/jpeg",
        ".png": "image/png",
        ".webp": "image/webp",
    }.get(suffix, "image/jpeg")

    with open(path, "rb") as f:
        encoded = base64.b64encode(f.read()).decode()
    return f"data:{mime};base64,{encoded}"


def parse_args():
    parser = argparse.ArgumentParser(
        description="从产品图片和产品描述直接生成社媒产品宣传视频",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例:
  python generate_video.py \
    --image-base64 /path/to/product.jpg \
    --description "一款高端护手霜，主打丝滑质地和快速吸收" \
    --audience "25-35岁都市女性" \
    --platform 小红书
        """,
    )

    input_group = parser.add_mutually_exclusive_group(required=False)
    input_group.add_argument("--image-base64", "--image", "-i", help="本地产品图片路径")
    input_group.add_argument("--image-url", "--url", "-u", help="公开可访问的产品图片 URL")
    input_group.add_argument("--text", "-t", help="仅文本模式，缺少图片时的降级方案")

    parser.add_argument("--description", "-d", help="产品描述，用于生成创意简报和提示词")
    parser.add_argument("--category", default="", help="产品品类")
    parser.add_argument("--audience", default="", help="目标人群")
    parser.add_argument("--platform", default="小红书", help="目标平台，默认小红书")
    parser.add_argument("--tone", default="高级、干净、利落", help="视频气质")
    parser.add_argument("--prompt", "-p", default="", help="手动覆盖自动生成的提示词")
    parser.add_argument("--duration", type=int, default=15, help="视频时长，默认 15 秒")
    parser.add_argument("--ratio", default="9:16", choices=["16:9", "9:16"], help="宽高比。单次任务必须固定一种比例")
    parser.add_argument("--resolution", default="720p", choices=["480p", "720p", "1080p"], help="分辨率")
    parser.add_argument("--model", default="doubao-seedance-1-5-pro-251215", help="模型名称")
    parser.add_argument("--watermark", action="store_true", help="添加水印")
    return parser.parse_args()


def build_content(args, prompt: str):
    if args.image_base64 or args.image_url:
        image_value = args.image_base64 if args.image_base64 else args.image_url
        if args.image_base64:
            image_value = image_to_data_url(args.image_base64)
        return [
            {"type": "text", "text": prompt},
            {"type": "image_url", "image_url": {"url": image_value}},
        ]

    if args.text:
        return [{"type": "text", "text": args.text}]

    print("错误: 请提供产品图片或文本输入")
    sys.exit(1)


def create_video_task(client, args, prompt: str):
    content = build_content(args, prompt)
    result = client.content_generation.tasks.create(
        model=args.model,
        content=content,
        duration=args.duration,
        watermark=args.watermark,
        ratio=args.ratio,
        resolution=args.resolution,
    )
    return result.id


def wait_for_result(client, task_id, max_attempts=30, interval=8):
    print(f"\n⏳ 任务已创建: {task_id}")
    print("⏳ 等待视频生成中...")
    print("=" * 50)

    for attempt in range(1, max_attempts + 1):
        result = client.content_generation.tasks.get(task_id=task_id)
        status = result.status
        progress = attempt * 100 // max_attempts
        bar = "█" * (attempt * 20 // max_attempts)
        print(f"\r  进度: {bar}{' ' * (20 - len(bar))} {progress}%", end="")

        if status == "succeeded":
            print("\n")
            print("=" * 50)
            print("✅ 视频生成成功!")
            print("=" * 50)
            print(f"📹 视频URL: {result.content.video_url}")
            print(f"⏱️  时长: {result.duration}秒")
            print(f"📐 分辨率: {result.resolution}")
            print(f"📐 宽高比: {result.ratio}")
            print("=" * 50)
            return result

        if status == "failed":
            print("\n")
            print("=" * 50)
            print("❌ 视频生成失败!")
            print(f"错误信息: {result.error}")
            print("=" * 50)
            return None

        if attempt < max_attempts:
            time.sleep(interval)

    print("\n")
    print("=" * 50)
    print("❌ 等待超时，任务仍在处理中")
    print(f"任务ID: {task_id}")
    print("=" * 50)
    return None


def main():
    load_env_files()
    args = parse_args()

    if not args.prompt and not args.description and not args.text:
        print("错误: 请提供 --description 让脚本自动生成提示词，或直接传入 --prompt")
        sys.exit(1)

    api_key = os.environ.get("SKYLARK_API_KEY")
    if not api_key:
        print("错误: 未设置 SKYLARK_API_KEY 环境变量")
        print("请在技能目录或 coze-video-gen-skill 目录下配置 .env")
        sys.exit(1)

    auto_prompt = args.prompt
    brief = None
    if not auto_prompt and args.description:
        category = args.category or infer_category(args.description)
        brief = build_marketing_brief(
            description=args.description,
            category=category,
            audience=args.audience,
            platform=args.platform,
            tone=args.tone,
            ratio=args.ratio,
        )
        auto_prompt = build_prompt(brief)

    final_prompt = auto_prompt or args.text

    print("=" * 50)
    print("🎬 产品宣传视频生成")
    print("=" * 50)
    print(f"🖼️  输入类型: {'图片' if (args.image_base64 or args.image_url) else '文本'}")
    if args.image_base64:
        print(f"🖼️  图片: {args.image_base64}")
    elif args.image_url:
        print(f"🖼️  图片URL: {args.image_url}")
    if args.description:
        print(f"📝 产品描述: {args.description}")
    print(f"⏱️  时长: {args.duration}秒")
    print(f"📐 比例: {args.ratio}")
    print(f"📐 分辨率: {args.resolution}")
    print(f"🎨 模型: {args.model}")
    print("=" * 50)

    if brief:
        print("创意简报：")
        print(f"- 品类: {brief['category']}")
        print(f"- 目标人群: {brief['audience']}")
        print(f"- 趋势方向: {brief['trend_direction']}")
        print(f"- 情绪钩子: {brief['emotional_hook']}")
        print(f"- 视觉钩子: {brief['visual_hook']}")
        print(f"- 场景方向: {brief['scene_direction']}")
        print(f"- 动态语言: {brief['motion_language']}")
        print(f"- 平台侧重: {brief['platform_style']}")
        print(f"- 转化策略: {brief['conversion_strategy']}")
        print(f"- 物理约束: {brief['physics_rules']}")
        print("=" * 50)

    print("最终提示词：")
    print(final_prompt)
    print("=" * 50)

    client = Ark(
        base_url="https://ark.cn-beijing.volces.com/api/v3",
        api_key=api_key,
    )

    try:
        task_id = create_video_task(client, args, final_prompt)
    except Exception as e:
        print(f"\n❌ 创建任务失败: {e}")
        sys.exit(1)

    result = wait_for_result(client, task_id)
    sys.exit(0 if result else 1)


if __name__ == "__main__":
    main()
