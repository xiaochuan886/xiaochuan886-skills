#!/usr/bin/env python3
"""End-to-end campaign generator: keyframes -> 2 segments -> final concat."""

import argparse
import base64
import json
import mimetypes
import os
import subprocess
import sys
import urllib.parse
import urllib.request
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

from build_prompt import build_marketing_brief, build_storyboard, infer_category, liquid_physics_rules  # noqa: E402


BAOYU_IMAGE_GEN = Path("/Users/luxiaochuan/.agents/skills/baoyu-image-gen/scripts/main.ts")
BAOYU_ENV = Path.home() / ".baoyu-skills" / "baoyu-image-gen" / ".env"
CONCAT_SCRIPT = SCRIPT_DIR / "concat_segments.py"


def load_env_file(path: Path) -> dict:
    values = {}
    if not path.exists():
        return values
    with open(path, "r", encoding="utf-8") as f:
        for raw_line in f:
            line = raw_line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, value = line.split("=", 1)
            values[key.strip()] = value.strip().strip('"').strip("'")
    return values


def load_skill_env():
    candidates = [
        SCRIPT_DIR.parent / ".env",
        Path("/Users/luxiaochuan/fuxingdaoOPC/coze-video-gen-skill/.env"),
        BAOYU_ENV,
    ]
    for path in candidates:
        for key, value in load_env_file(path).items():
            os.environ.setdefault(key, value)


def image_to_data_url(image_path: str) -> str:
    path = Path(image_path).expanduser().resolve()
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


def image_to_inline_data(image_path: str) -> dict:
    path = Path(image_path).expanduser().resolve()
    mime, _ = mimetypes.guess_type(path.name)
    mime = mime or "image/jpeg"
    with open(path, "rb") as f:
        encoded = base64.b64encode(f.read()).decode()
    return {"mime_type": mime, "data": encoded}


def is_url(value: str) -> bool:
    parsed = urllib.parse.urlparse(value)
    return parsed.scheme in {"http", "https"} and bool(parsed.netloc)


def prepare_source_image(image_input: str, work_dir: Path) -> Path:
    if is_url(image_input):
        suffix = Path(urllib.parse.urlparse(image_input).path).suffix or ".jpg"
        target = work_dir / f"source{suffix}"
        urllib.request.urlretrieve(image_input, target)
        return target
    return Path(image_input).expanduser().resolve()


def read_text_file(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8").strip()
    except UnicodeDecodeError:
        return path.read_text(encoding="utf-8", errors="ignore").strip()


def resolve_input_dir(input_dir: str) -> dict:
    root = Path(input_dir).expanduser().resolve()
    if not root.exists() or not root.is_dir():
        raise SystemExit(f"输入目录不存在: {input_dir}")

    image_candidates = [
        path for path in sorted(root.iterdir())
        if path.is_file() and path.suffix.lower() in {".jpg", ".jpeg", ".png", ".webp"}
    ]
    if not image_candidates:
        raise SystemExit(f"输入目录中未找到图片: {root}")

    text_candidates = [
        path for path in sorted(root.iterdir())
        if path.is_file() and path.suffix.lower() in {".md", ".txt"} and not path.name.startswith(".")
    ]

    preferred_copy = root / "文案.md"
    ordered_texts = []
    if preferred_copy in text_candidates:
        ordered_texts.append(preferred_copy)
    ordered_texts.extend(path for path in text_candidates if path != preferred_copy)

    copy_parts = []
    for path in ordered_texts:
        content = read_text_file(path)
        if content:
            copy_parts.append(content)

    return {
        "input_dir": str(root),
        "image_path": str(image_candidates[0]),
        "copy_text": "\n\n".join(copy_parts).strip(),
        "text_files": [str(path) for path in ordered_texts],
        "image_files": [str(path) for path in image_candidates],
    }


def run(cmd, env=None):
    return subprocess.run(cmd, check=True, text=True, capture_output=True, env=env)


def extract_json_block(text: str) -> dict:
    cleaned = text.strip()
    if cleaned.startswith("```"):
        lines = cleaned.splitlines()
        if len(lines) >= 3:
            cleaned = "\n".join(lines[1:-1]).strip()
    return json.loads(cleaned)


def analyze_materials_with_gemini(image_path: str, copy_text: str) -> dict:
    api_key = os.environ.get("GEMINI_API_KEY") or os.environ.get("GOOGLE_API_KEY")
    if not api_key:
        return {}

    prompt = (
        "你是一个社交媒体产品视频策划助手。请同时理解这张 SKU 产品图和提供的核心文案，"
        "输出严格 JSON，不要输出额外解释。"
        "请提取：product_name, category, summary, audience, selling_points, visible_text, scene_direction, "
        "visual_hook, segment_1_copy, segment_2_copy, visual_keywords, has_packaging, packaging_summary。"
        "要求：1) category 必须只返回以下英文枚举之一：beauty, skincare, cosmetics, jewelry, luxury, food, drink, electronics, home, fashion, product；"
        "2) summary 是 1-2 句适合后续视频脚本使用的产品摘要；"
        "3) segment_1_copy 和 segment_2_copy 是两段有衔接、不重复的短旁白思路；"
        "4) has_packaging 必须是布尔值。只有在源图里明确存在产品瓶身、袋身、盒身、罐身等可辨认包装主体时才返回 true；"
        "5) packaging_summary 仅描述源图中真实可见的包装外观，不可脑补不存在的包装；如果没有包装就返回空字符串；"
        "6) 如果文案为空，优先从图片中的可见文字和包装信息推断；"
        f"5) 现有文案如下：{copy_text or '无额外文案，请完全根据图片可见信息提取。'}"
    )
    payload = {
        "contents": [{
            "parts": [
                {"text": prompt},
                {"inline_data": image_to_inline_data(image_path)},
            ]
        }],
        "generationConfig": {
            "responseMimeType": "application/json",
        },
    }
    candidate_models = [
        os.environ.get("PROMO_VISION_MODEL", "").strip(),
        "gemini-2.5-flash",
        "gemini-3-flash-preview",
        "gemini-2.5-flash-lite",
    ]
    last_error = None
    for model in [item for item in candidate_models if item]:
        url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={api_key}"
        request = urllib.request.Request(
            url,
            data=json.dumps(payload).encode("utf-8"),
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        try:
            with urllib.request.urlopen(request, timeout=90) as response:
                data = json.loads(response.read().decode("utf-8"))
            text = data["candidates"][0]["content"]["parts"][0]["text"]
            analysis = extract_json_block(text)
            analysis["vision_model"] = model
            return analysis
        except Exception as exc:
            last_error = exc
            continue

    if last_error:
        print(f"Warning: Gemini 素材理解失败，回退到规则模式: {last_error}", file=sys.stderr)
    return {}


def wait_for_result(client, task_id, max_attempts=30, interval=8):
    import time

    for _ in range(max_attempts):
        result = client.content_generation.tasks.get(task_id=task_id)
        if result.status == "succeeded":
            return result
        if result.status == "failed":
            raise RuntimeError(f"视频生成失败: {result.error}")
        time.sleep(interval)
    raise TimeoutError(f"视频生成超时: {task_id}")


def create_video_task(client, image_path: str, prompt: str, ratio: str, duration: int, resolution: str, model: str):
    content = [
        {"type": "text", "text": prompt},
        {"type": "image_url", "image_url": {"url": image_to_data_url(image_path)}},
    ]
    result = client.content_generation.tasks.create(
        model=model,
        content=content,
        duration=duration,
        watermark=False,
        ratio=ratio,
        resolution=resolution,
    )
    return result.id


def ratio_words(ratio: str) -> dict:
    if ratio == "16:9":
        return {
            "framing": "横屏16:9",
            "start": "偏全景到中景",
            "second": "近景到hero shot",
            "environment": "适合展示产地环境、景深和产品与场景的空间关系",
        }
    return {
        "framing": "竖屏9:16",
        "start": "近景到中近景",
        "second": "近景到产品hero竖版定帧",
        "environment": "适合突出产品主体、特写细节与移动端社交媒体观看",
    }


def output_slug(description: str, category: str) -> str:
    source = category or infer_category(description) or "campaign"
    slug = "".join(ch if ch.isalnum() else "-" for ch in source.lower())[:40].strip("-")
    return slug or "campaign"


def path_slug(path_value: str) -> str:
    name = Path(path_value).expanduser().resolve().name
    slug = "".join(ch if ch.isalnum() else "-" for ch in name.lower()).strip("-")
    return slug or "task"


def build_keyframe_tasks(source_image: str, brief: dict, storyboard: dict, out_dir: Path) -> dict:
    ratio = brief["ratio"]
    words = ratio_words(ratio)
    provider = "google"
    model = "gemini-3.1-flash-image-preview"
    ar = ratio
    quality = "2k"

    base = {
        "provider": provider,
        "model": model,
        "ar": ar,
        "quality": quality,
        "ref": [source_image],
    }

    seg1 = storyboard["segment_1"]
    seg2 = storyboard["segment_2"]
    has_packaging = bool(brief.get("has_packaging", False))
    product_anchor = "产品包装" if has_packaging else "产品主体"
    liquid_guardrail = brief.get("liquid_physics_rules", "")
    no_packaging_drink_guardrail = (
        "源图只有鲜果与产地场景，没有零售包装。若需要表达饮用，只允许出现透明无标玻璃杯中的原汁；禁止出现任何瓶子、盒子、袋子、罐身、标签、品牌字样、喷头或印刷文字。"
        if not has_packaging and brief.get("category") == "drink"
        else ""
    )
    packaging_guardrail = (
        "允许保留源图中真实可见的包装主体与包装上的原始文字，但不允许新增、改写或脑补任何包装设计。"
        if has_packaging
        else "源图未确认存在产品包装，禁止新增任何瓶身、袋身、盒身、罐身或标签设计，只能沿用源图里已存在的产品主体。"
    )
    prompts = {
        "seg1-start": (
            f"基于参考产品图，生成一张{words['framing']}电影感广告关键帧。"
            f"这是第一段开场画面，核心任务是{seg1['purpose']}，采用{seg1['opening_shot']}，"
            f"{seg1['visual_goal']} 画面保持真实商业摄影质感，{product_anchor}外观与参考图一致。"
            "除源图中原本就存在的包装文字外，画面中禁止出现任何新文字、字幕、贴纸、logo 或排版。"
            f"{packaging_guardrail}{no_packaging_drink_guardrail}{liquid_guardrail}"
        ),
        "seg1-end": (
            f"基于参考产品图，生成一张{words['framing']}电影感广告关键帧。"
            f"这是第一段结尾画面，镜头已经过渡到{seg1['ending_shot']}，"
            f"{product_anchor}、原料和环境层次更清晰，适合作为向第二段交接的稳定收束画面。"
            "保持物体比例、光线和空间关系真实。除源图原有包装文字外，禁止任何新增文字。"
            f"{packaging_guardrail}{no_packaging_drink_guardrail}{liquid_guardrail}"
        ),
        "seg2-start": (
            f"基于参考产品图，生成一张{words['framing']}电影感广告关键帧。"
            f"这是第二段开场画面，承接第一段，采用{seg2['opening_shot']}，"
            f"重点表达{seg2['purpose']}。保持参考图中的{product_anchor}、原料与场景关系一致。"
            "除源图原有包装文字外，禁止任何新增文字、字幕或标签。"
            f"{packaging_guardrail}{no_packaging_drink_guardrail}{liquid_guardrail}"
        ),
        "seg2-end": (
            f"基于参考产品图，生成一张{words['framing']}电影感广告关键帧。"
            f"这是第二段结尾的最终收束画面，采用{seg2['ending_shot']}，"
            f"{product_anchor}成为绝对视觉中心，原料和环境作为可信赖陪衬，形成适合广告结尾的购买冲动画面。"
            "保持真实光线与商业摄影质感。除源图原有包装文字外，禁止任何新增文字。"
            f"{packaging_guardrail}{no_packaging_drink_guardrail}{liquid_guardrail}"
        ),
    }

    tasks = []
    for key, prompt in prompts.items():
        task = {
            "id": key,
            "prompt": prompt,
            "image": str(out_dir / f"{key}.png"),
            **base,
        }
        tasks.append(task)
    return {"jobs": 2, "tasks": tasks}


def build_segment_prompts(brief: dict, storyboard: dict) -> tuple[str, str]:
    words = ratio_words(brief["ratio"])
    seg1_meta = storyboard["segment_1"]
    seg2_meta = storyboard["segment_2"]
    has_packaging = bool(brief.get("has_packaging", False))
    product_anchor = "包装主体" if has_packaging else "产品主体"
    packaging_guardrail = (
        "保持源图里的包装外观和可见标签完全一致，不新增任何不存在的包装结构或文字。"
        if has_packaging
        else "源图没有确认包装时，禁止生成任何新的包装、瓶身、盒身、袋身或标签。"
    )
    no_packaging_drink_guardrail = (
        "这是一张只有鲜果与产地环境的源图；如需表达饮用场景，只允许透明无标玻璃杯中的原汁，禁止出现任何零售瓶、包装盒、袋装、喷头、标签、品牌字样或额外文字。"
        if not has_packaging and brief.get("category") == "drink"
        else ""
    )
    liquid_guardrail = brief.get("liquid_physics_rules", "")
    seg1 = (
        f"以这张关键帧为起点，生成 {brief['segment_duration']} 秒 {words['framing']} 自然流畅的广告镜头。"
        f"镜头职责是{seg1_meta['purpose']}，整体构图从{seg1_meta['opening_shot']}自然推进到{seg1_meta['ending_shot']}，"
        f"{seg1_meta['visual_goal']} 镜头运动使用{seg1_meta['camera_move']}。"
        f"保持{product_anchor}、原料和环境的真实比例、接触关系和光线稳定，只允许轻微风动或自然推进。"
        f"{seg1_meta.get('physics_focus', '')}{packaging_guardrail}{no_packaging_drink_guardrail}{liquid_guardrail}"
        f"建议旁白表达为：{seg1_meta['spoken_copy']} 旁白语气自然克制，不重复，不出现其他无关台词。"
    )
    seg2 = (
        f"以这张关键帧为起点，生成 {brief['segment_duration']} 秒 {words['framing']} 自然流畅的广告镜头。"
        f"镜头职责是承接上一段并完成{seg2_meta['purpose']}，从{seg2_meta['opening_shot']}自然过渡到{seg2_meta['ending_shot']}，"
        f"{seg2_meta['visual_goal']} 镜头运动使用{seg2_meta['camera_move']}。"
        f"保持{product_anchor}、原料与环境的真实关系稳定，用轻微横移、轻微拉开或柔和推进完成景别变化。"
        f"{seg2_meta.get('physics_focus', '')}{packaging_guardrail}{no_packaging_drink_guardrail}{liquid_guardrail}"
        f"建议旁白表达为：{seg2_meta['spoken_copy']} 旁白语义承接上一段，但不要重复上一段内容。"
    )
    return seg1, seg2


def ensure_required_keyframes(keyframe_dir: Path) -> None:
    required = [
        keyframe_dir / "seg1-start.png",
        keyframe_dir / "seg1-end.png",
        keyframe_dir / "seg2-start.png",
        keyframe_dir / "seg2-end.png",
    ]
    missing = [str(path) for path in required if not path.exists()]
    if missing:
        raise RuntimeError(f"关键帧生成不完整，缺少文件: {missing}")


def run_baoyu_batch(batch_file: Path):
    env = os.environ.copy()
    env.update(load_env_file(BAOYU_ENV))
    cmd = ["npx", "-y", "bun", str(BAOYU_IMAGE_GEN), "--batchfile", str(batch_file), "--json"]
    result = run(cmd, env=env)
    if '"failed": 0' not in result.stdout and '"failed":0' not in result.stdout:
        raise RuntimeError(f"关键帧生成失败:\n{result.stdout}\n{result.stderr}")
    return result.stdout


def parse_args():
    parser = argparse.ArgumentParser(description="Generate a full 2-segment product promo campaign.")
    parser.add_argument("--image-base64", "--image", default="", help="Source product image path or public image URL")
    parser.add_argument("--input-dir", default="", help="Folder containing SKU image and optional copy files")
    parser.add_argument("--description", default="", help="Product description")
    parser.add_argument("--category", default="", help="Product category")
    parser.add_argument("--audience", default="", help="Target audience")
    parser.add_argument("--platform", default="小红书", help="Target platform")
    parser.add_argument("--tone", default="高级、自然、纯净、可信赖", help="Creative tone")
    parser.add_argument("--ratio", default="16:9", choices=["16:9", "9:16"], help="Campaign ratio")
    parser.add_argument("--segment-duration", type=int, default=7, help="Duration per segment")
    parser.add_argument("--resolution", default="720p", choices=["480p", "720p", "1080p"])
    parser.add_argument("--model", default="doubao-seedance-1-5-pro-251215")
    parser.add_argument("--out-dir", default="", help="Output directory; defaults to output/<category>-<ratio>/")
    return parser.parse_args()


def main():
    args = parse_args()
    load_skill_env()

    api_key = os.environ.get("SKYLARK_API_KEY")
    if not api_key:
        raise SystemExit("未找到 SKYLARK_API_KEY")

    slug = output_slug(args.description, args.category)
    if not args.image_base64 and not args.input_dir:
        raise SystemExit("请提供 --image 或 --input-dir")

    input_bundle = {}
    if args.input_dir:
        input_bundle = resolve_input_dir(args.input_dir)
        if not args.image_base64:
            args.image_base64 = input_bundle["image_path"]
        if not args.description and input_bundle["copy_text"]:
            args.description = input_bundle["copy_text"]

    analysis_seed = args.description or ""
    initial_category = args.category or infer_category(analysis_seed)
    base_slug = output_slug(analysis_seed or "campaign", initial_category)
    if args.input_dir:
        slug = f"{path_slug(args.input_dir)}-{base_slug}"
    else:
        slug = base_slug
    default_out_dir = SCRIPT_DIR.parent / "output" / f"{slug}-{args.ratio.replace(':', 'x')}"
    out_dir = Path(args.out_dir).expanduser().resolve() if args.out_dir else default_out_dir.resolve()
    keyframe_dir = out_dir / "keyframes"
    campaign_dir = out_dir / "campaign"
    keyframe_dir.mkdir(parents=True, exist_ok=True)
    campaign_dir.mkdir(parents=True, exist_ok=True)
    source_dir = out_dir / "source"
    source_dir.mkdir(parents=True, exist_ok=True)

    source_image = prepare_source_image(args.image_base64, source_dir)
    if not source_image.exists():
        raise SystemExit(f"未找到源图片: {args.image_base64}")

    input_analysis = analyze_materials_with_gemini(str(source_image), input_bundle.get("copy_text", args.description))
    if not args.description:
        args.description = input_analysis.get("summary", "") or input_bundle.get("copy_text", "")
    if not args.description:
        raise SystemExit("未能从输入目录或图片中提取有效产品文案，请补充 --description 或完善 文案.md")

    category = args.category or input_analysis.get("category", "") or infer_category(args.description)
    brief = build_marketing_brief(
        description=args.description,
        category=category,
        audience=args.audience or input_analysis.get("audience", ""),
        platform=args.platform,
        tone=args.tone,
        ratio=args.ratio,
    )
    brief["has_packaging"] = bool(input_analysis.get("has_packaging", False))
    brief["segment_duration"] = args.segment_duration
    if input_analysis.get("visual_hook"):
        brief["visual_hook"] = input_analysis["visual_hook"]
    if input_analysis.get("scene_direction"):
        brief["scene_direction"] = input_analysis["scene_direction"]
    if input_analysis.get("visual_keywords"):
        keywords = input_analysis["visual_keywords"]
        brief["visual_keywords"] = "、".join(keywords) if isinstance(keywords, list) else str(keywords)
        if "liquid_physics_rules" in brief:
            brief["liquid_physics_rules"] = liquid_physics_rules(args.description, brief["visual_keywords"])
    if input_analysis.get("segment_1_copy"):
        brief["copy_open"] = input_analysis["segment_1_copy"]
    if input_analysis.get("segment_2_copy"):
        brief["copy_close"] = input_analysis["segment_2_copy"]
    storyboard = build_storyboard(brief, args.segment_duration)

    batch = build_keyframe_tasks(str(source_image), brief, storyboard, keyframe_dir)
    batch_file = keyframe_dir / "batch.json"
    batch_file.write_text(json.dumps(batch, ensure_ascii=False, indent=2), encoding="utf-8")
    print("Generating keyframes with baoyu-image-gen...")
    run_baoyu_batch(batch_file)
    ensure_required_keyframes(keyframe_dir)

    seg1_prompt, seg2_prompt = build_segment_prompts(brief, storyboard)
    client = Ark(base_url="https://ark.cn-beijing.volces.com/api/v3", api_key=api_key)

    seg1_start = keyframe_dir / "seg1-start.png"
    seg2_start = keyframe_dir / "seg2-start.png"

    print("Generating segment 1...")
    seg1_task = create_video_task(client, str(seg1_start), seg1_prompt, args.ratio, args.segment_duration, args.resolution, args.model)
    seg1_result = wait_for_result(client, seg1_task)

    print("Generating segment 2...")
    seg2_task = create_video_task(client, str(seg2_start), seg2_prompt, args.ratio, args.segment_duration, args.resolution, args.model)
    seg2_result = wait_for_result(client, seg2_task)

    concat_cmd = [
        sys.executable,
        str(CONCAT_SCRIPT),
        "--video-url-1", seg1_result.content.video_url,
        "--video-url-2", seg2_result.content.video_url,
        "--out-dir", str(campaign_dir),
        "--output-name", f"final-campaign-{args.ratio.replace(':', 'x')}.mp4",
    ]
    run(concat_cmd)

    report = {
        "category": category,
        "description": args.description,
        "ratio": args.ratio,
        "segment_duration": args.segment_duration,
        "creative_thesis": storyboard["creative_thesis"],
        "narrative_handoff": storyboard["narrative_handoff"],
        "input_bundle": input_bundle,
        "input_analysis": input_analysis,
        "has_packaging": brief["has_packaging"],
        "segment_1_copy": storyboard["segment_1"]["spoken_copy"],
        "segment_2_copy": storyboard["segment_2"]["spoken_copy"],
        "storyboard": storyboard,
        "segment_1_prompt": seg1_prompt,
        "segment_2_prompt": seg2_prompt,
        "segment_1_url": seg1_result.content.video_url,
        "segment_2_url": seg2_result.content.video_url,
        "final_video": str(campaign_dir / f"final-campaign-{args.ratio.replace(':', 'x')}.mp4"),
        "source_image": str(source_image),
        "keyframes": {
            "seg1_start": str(keyframe_dir / "seg1-start.png"),
            "seg1_end": str(keyframe_dir / "seg1-end.png"),
            "seg2_start": str(keyframe_dir / "seg2-start.png"),
            "seg2_end": str(keyframe_dir / "seg2-end.png"),
        },
    }
    report_path = out_dir / "campaign-report.json"
    report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")

    print("Campaign complete")
    print(f"Report: {report_path}")
    print(f"Final video: {report['final_video']}")


if __name__ == "__main__":
    main()
