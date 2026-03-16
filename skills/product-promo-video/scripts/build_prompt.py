#!/usr/bin/env python3
"""Build creative briefs, storyboards, and prompt drafts for product promo videos."""

import argparse
import os


CATEGORY_MOTION = {
    "beauty": "柔和高光掠过产品表面，液体或精华质地被微距放大，水珠与光泽流动，画面精致通透",
    "skincare": "柔和高光掠过产品表面，液体或精华质地被微距放大，水珠与光泽流动，画面精致通透",
    "cosmetics": "妆效质感被放大，镜头快速切换产品外观、刷头或膏体细节，氛围时尚高级",
    "jewelry": "产品缓慢旋转，细碎闪光与柔焦高光营造高级感，镜头捕捉金属与宝石反射",
    "luxury": "丝绒般阴影与高级反光衬托产品，镜头节奏克制但吸睛，强调奢华仪式感",
    "food": "液体飞溅、热气或新鲜质感被近距离展示，节奏更明快，更有食欲刺激",
    "drink": "冷凝水、飞溅、气泡和高能切镜增强清爽与即时购买欲",
    "electronics": "利落镜头运动、冷色高光、精密结构特写与科技感反射强化产品性能印象",
    "home": "温暖生活化场景与材质细节结合，镜头柔和推进，强调舒适和品质",
    "fashion": "镜头聚焦面料、剪裁和佩戴效果，节奏时髦，带有轻微大片感和穿搭种草气质",
}


PLATFORM_STYLE = {
    "小红书": "整体更像高转化种草短视频，精致、真实、容易激发收藏和咨询",
    "xiaohongshu": "整体更像高转化种草短视频，精致、真实、容易激发收藏和咨询",
    "抖音": "前两秒必须更抓人，镜头切换更快，节奏更强，突出购买冲动",
    "douyin": "前两秒必须更抓人，镜头切换更快，节奏更强，突出购买冲动",
    "tiktok": "画面节奏更国际化，强调快速吸睛、强视觉冲击和移动端传播性",
    "instagram": "更注重质感、构图和品牌感，像精致 reels 广告短片",
    "instagram reels": "更注重质感、构图和品牌感，像精致 reels 广告短片",
}


CATEGORY_STRATEGY = {
    "drink": {
        "product_role": "天然原液主角",
        "audience_fantasy": "把原产地纯净营养装进日常补给",
        "trend_language": "产地信任感、鲜果到原液、洁净质感、真实商业摄影",
        "scene_direction": "先建立产地与鲜果世界，再回到成品主体的可信赖 hero shot",
        "conversion_energy": "种草式购买冲动，强调每天都能轻松拥有",
        "segment_1_focus": "产地与原料信任",
        "segment_2_focus": "成品与日常饮用转化",
        "copy_open": "高海拔原产地，孕育更干净的刺梨原料。",
        "copy_close": "从鲜果到原液，把高原纯净带进每天。",
        "visual_keywords": "鲜果纹理、自然暖阳、竹筛、原液主体、轻微露珠、真实果园景深",
    },
    "food": {
        "product_role": "食欲型主角产品",
        "audience_fantasy": "天然好吃又放心，能马上想尝试",
        "trend_language": "质感特写、食欲刺激、真实原料、轻快镜头节奏",
        "scene_direction": "先建立真实原料，再突出成品诱人质感",
        "conversion_energy": "立刻想尝试和下单",
        "segment_1_focus": "原料与新鲜感",
        "segment_2_focus": "质感与入口想象",
        "copy_open": "看得见的新鲜原料，决定了更放心的味道。",
        "copy_close": "把真实风味装进这一口，吃得到自然满足。",
        "visual_keywords": "食材近景、纹理、蒸汽或清爽感、真实摆盘、产品主体 hero",
    },
    "beauty": {
        "product_role": "自我护理仪式感主角",
        "audience_fantasy": "用更高级的护理感完成生活升级",
        "trend_language": "精致高光、微距质感、轻奢镜头、顺滑流动",
        "scene_direction": "先建立高级质感，再回到功效和日常使用想象",
        "conversion_energy": "温和种草，强调精致生活方式",
        "segment_1_focus": "高级质感与核心成分信任",
        "segment_2_focus": "使用价值与日常拥有感",
        "copy_open": "看得见的高级质感，来自更用心的原料与配方。",
        "copy_close": "把细腻护理装进每天，让状态自然更好。",
        "visual_keywords": "高光扫过、精华流动、通透质地、极简背景、产品 hero",
    },
}

DEFAULT_STRATEGY = {
    "product_role": "产品主角",
    "audience_fantasy": "让用户产生拥有它会更好的想象",
    "trend_language": "真实高级、清晰层次、物理自然、社交媒体友好",
    "scene_direction": "先建立可信赖场景，再走向成品 hero 收尾",
    "conversion_energy": "自然种草和购买兴趣",
    "segment_1_focus": "产品来源与信任感",
    "segment_2_focus": "产品价值与拥有感",
    "copy_open": "更用心的来源，决定了更可信赖的品质。",
    "copy_close": "把它带进日常，让每一次使用都更值得。",
    "visual_keywords": "产品主体、真实材质、稳定光线、清晰主次关系",
}


def infer_category(description: str) -> str:
    text = description.lower()
    keyword_map = {
        "beauty": ["护手霜", "精华", "面霜", "口红", "香水", "护肤", "化妆", "skincare", "serum", "cream", "lipstick", "perfume", "hand cream"],
        "jewelry": ["项链", "戒指", "耳环", "珠宝", "diamond", "ring", "necklace", "jewelry"],
        "food": ["零食", "饼干", "巧克力", "食品", "snack", "cookie", "chocolate", "food"],
        "drink": ["饮料", "咖啡", "茶", "果汁", "原液", "果饮", "饮品", "刺梨", "drink", "coffee", "tea", "juice"],
        "electronics": ["耳机", "手机", "相机", "音箱", "充电", "headphone", "phone", "camera", "speaker"],
        "home": ["家居", "香薰", "杯子", "床品", "灯具", "home", "candle", "mug"],
        "fashion": ["包", "鞋", "服装", "穿搭", "bag", "shoe", "fashion", "dress"],
        "luxury": ["奢侈", "高定", "礼盒", "luxury"],
    }
    priority = ["beauty", "jewelry", "luxury", "electronics", "home", "fashion", "food", "drink"]
    for category in priority:
        keywords = keyword_map[category]
        if any(keyword in text for keyword in keywords):
            return category
    return "product"


def category_motion_text(category: str) -> str:
    return CATEGORY_MOTION.get(category.lower(), "镜头围绕产品做近景和特写切换，强调材质、轮廓、光泽和购买冲动")


def platform_style_text(platform: str) -> str:
    return PLATFORM_STYLE.get(platform.lower(), PLATFORM_STYLE.get(platform, "整体符合移动端社交媒体爆款短视频的吸睛节奏和转化导向"))


def ratio_framing_text(ratio: str) -> str:
    if ratio == "16:9":
        return "横屏 16:9，构图更舒展，适合展示中景、环境关系和产品与产地场景的联动"
    return "竖屏 9:16，构图更集中，适合突出特写、近景和移动端社交媒体传播"


def ratio_plan(ratio: str) -> dict:
    if ratio == "16:9":
        return {
            "opening_shot": "全景到中景建立镜头",
            "product_shot": "中景到近景推进",
            "hero_shot": "近景到横版 hero shot",
            "camera_style": "缓慢推进、轻微横移、稳定空间关系",
        }
    return {
        "opening_shot": "近景到中近景抓取主体",
        "product_shot": "近景到特写推进",
        "hero_shot": "近景到竖版 hero 定帧",
        "camera_style": "轻推近、轻微环绕、主体居中稳定",
    }


def packaging_language(has_packaging: bool) -> dict:
    if has_packaging:
        return {
            "product_anchor": "成品包装",
            "product_surface": "包装外观",
            "hero_subject": "成品包装和可见标签信息",
        }
    return {
        "product_anchor": "产品主体",
        "product_surface": "产品主体外观",
        "hero_subject": "产品主体和原始图像中已存在的可见元素",
    }


def no_packaging_scene_rules(category: str) -> dict:
    if category.lower() == "drink":
        return {
            "segment_2_focus": "鲜果到原汁的自然转化与日常饮用想象",
            "hero_subject": "透明无标玻璃杯中的原汁、鲜果与原产地环境",
            "scene_direction": "先建立产地与鲜果世界，再用透明无标玻璃杯中的原汁完成可信赖收尾",
            "copy_close": "把刺梨鲜果的自然纯净，变成每天都能放心喝的一杯原汁。",
            "visual_keywords": "鲜果纹理、自然暖阳、果园景深、透明玻璃杯、琥珀色原汁、无包装无标签",
            "guardrail": "源图没有零售包装时，如需表达饮用场景，只允许出现透明无标玻璃杯中的液体，不允许出现任何瓶子、盒子、袋子、罐身、喷头、标签或品牌文字。",
        }
    return {
        "segment_2_focus": "",
        "hero_subject": "",
        "scene_direction": "",
        "copy_close": "",
        "visual_keywords": "",
        "guardrail": "",
    }


def category_strategy(category: str) -> dict:
    return CATEGORY_STRATEGY.get(category.lower(), DEFAULT_STRATEGY)


def liquid_physics_rules(description: str, visual_keywords: str = "") -> str:
    text = f"{description} {visual_keywords}".lower()
    liquid_signals = ["杯", "液体", "原液", "果汁", "饮", "drink", "juice", "pour", "倒入", "玻璃杯", "杯子"]
    if any(signal in text for signal in liquid_signals):
        return (
            "如果画面出现杯子、玻璃容器、瓶口、袋口或倒液动作，必须把容器视为完整密闭实体："
            "液体只能从可见开口流出并落入容器开口内部，流线连续向下，受重力控制；"
            "杯底、杯壁和容器外轮廓保持完整，不允许液体从杯底、杯壁或悬空位置渗漏、穿模或凭空出现；"
            "液面变化只发生在容器内部，并与倒入动作同步。"
        )
    return ""


def build_marketing_brief(description: str, category: str, audience: str, platform: str, tone: str, ratio: str = "9:16") -> dict:
    audience_text = audience if audience else "该产品的潜在核心消费者"
    tone_text = tone if tone else "高级、利落、精致"
    strategy = category_strategy(category)

    return {
        "category": category,
        "audience": audience_text,
        "tone": tone_text,
        "description": description,
        "ratio": ratio,
        "ratio_framing": ratio_framing_text(ratio),
        "platform_style": platform_style_text(platform),
        "motion_language": category_motion_text(category),
        "selling_point": "突出最容易被短视频镜头放大的核心卖点、质感差异和使用价值",
        "emotional_hook": "让用户迅速产生想了解、收藏、咨询或购买的冲动",
        "visual_hook": "开场用高识别度产品特写、推进镜头、材质反光或使用瞬间快速抓住注意力",
        "trend_direction": "参考同类竞品爆款的节奏、构图和氛围趋势，但不模仿具体品牌和广告资产",
        "conversion_strategy": "前段抢注意力，中段强化卖点和情绪价值，结尾形成明确种草与下单想象",
        "scene_direction": strategy["scene_direction"],
        "physics_rules": "保持主体比例、接触关系、光线方向与背景空间关系稳定，动作符合重力、惯性和材质特性，单镜头只保留一个主动作与一个简单镜头运动",
        "product_role": strategy["product_role"],
        "audience_fantasy": strategy["audience_fantasy"],
        "trend_language": strategy["trend_language"],
        "conversion_energy": strategy["conversion_energy"],
        "segment_1_focus": strategy["segment_1_focus"],
        "segment_2_focus": strategy["segment_2_focus"],
        "copy_open": strategy["copy_open"],
        "copy_close": strategy["copy_close"],
        "visual_keywords": strategy["visual_keywords"],
        "ratio_plan": ratio_plan(ratio),
        "liquid_physics_rules": liquid_physics_rules(description, strategy["visual_keywords"]),
    }


def build_prompt(brief: dict) -> str:
    return (
        f"以产品实物为绝对主角，{brief['ratio_framing']}，15 秒社交媒体产品宣传短片，整体风格{brief['tone']}，"
        f"{brief['trend_direction']}。"
        f"产品信息：{brief['description']}。目标人群：{brief['audience']}。"
        "开场 0-3 秒必须快速吸睛，用极具冲击力的产品特写、推进镜头、开盒或亮相瞬间抓住注意力；"
        "3-7 秒展示产品 hero angle 和核心卖点，用多角度近景、中景和光影变化强化高级感；"
        f"7-11 秒进一步突出使用价值、材质细节和情绪价值，{brief['motion_language']}；"
        f"11-15 秒以强记忆点的产品 hero shot 收尾，体现{brief['conversion_strategy']}。"
        f"{brief['platform_style']}。"
        f"{brief['physics_rules']}。"
        f"{brief['liquid_physics_rules']}。"
        "镜头流畅，层次清楚，突出产品本身，避免复杂字幕，避免品牌模仿，无水印。"
    )


def build_storyboard(brief: dict, segment_duration: int = 7) -> dict:
    ratio_meta = brief["ratio_plan"]
    has_packaging = bool(brief.get("has_packaging", False))
    packaging_meta = packaging_language(has_packaging)
    no_packaging_meta = no_packaging_scene_rules(brief["category"]) if not has_packaging else {}
    segment_1 = {
        "purpose": brief["segment_1_focus"],
        "spoken_copy": brief["copy_open"],
        "opening_shot": ratio_meta["opening_shot"],
        "middle_shot": "产品与原料同框，中景建立信任感",
        "ending_shot": ratio_meta["product_shot"],
        "camera_move": ratio_meta["camera_style"],
        "visual_goal": f"突出{brief['visual_keywords']}，先讲来源、原料、产地和真实感。",
        "physics_focus": brief.get("liquid_physics_rules", "") or brief["physics_rules"],
    }
    segment_2 = {
        "purpose": no_packaging_meta.get("segment_2_focus") or brief["segment_2_focus"],
        "spoken_copy": no_packaging_meta.get("copy_close") or brief["copy_close"],
        "opening_shot": ratio_meta["product_shot"],
        "middle_shot": "质感细节与成品价值被进一步放大",
        "ending_shot": ratio_meta["hero_shot"],
        "camera_move": ratio_meta["camera_style"],
        "visual_goal": f"承接上一段，回到{no_packaging_meta.get('hero_subject') or packaging_meta['hero_subject']}和使用想象，完成转化收尾。",
        "physics_focus": (
            (brief.get("liquid_physics_rules", "") or brief["physics_rules"])
            + (no_packaging_meta.get("guardrail", "") or "")
        ),
    }
    return {
        "creative_thesis": (
            f"把 {brief['product_role']} 放在最可信赖的真实场景里，"
            f"用 {brief['trend_language']} 的方式完成从吸引注意到产生购买兴趣的两段式叙事。"
        ),
        "narrative_handoff": f"第一段先讲{segment_1['purpose']}，第二段承接到{segment_2['purpose']}，避免重复表达。",
        "segment_duration": segment_duration,
        "segment_1": segment_1,
        "segment_2": segment_2,
    }


def main():
    parser = argparse.ArgumentParser(description="Build a product promo creative brief and prompt draft for Seedance video generation.")
    parser.add_argument("--image", help="Local image path or image URL for reference only", default="")
    parser.add_argument("--description", required=True, help="Product description")
    parser.add_argument("--category", default="", help="Product category")
    parser.add_argument("--audience", default="", help="Target audience")
    parser.add_argument("--platform", default="小红书", help="Target platform")
    parser.add_argument("--tone", default="高级、干净、利落", help="Video tone")
    parser.add_argument("--ratio", default="9:16", choices=["16:9", "9:16"], help="Aspect ratio")
    parser.add_argument("--segment-duration", type=int, default=7, help="Storyboard segment duration")
    args = parser.parse_args()

    category = args.category or infer_category(args.description)
    brief = build_marketing_brief(
        description=args.description,
        category=category,
        audience=args.audience,
        platform=args.platform,
        tone=args.tone,
        ratio=args.ratio,
    )
    prompt = build_prompt(brief)
    storyboard = build_storyboard(brief, args.segment_duration)

    if args.image:
        image_hint = f"参考素材：{os.path.abspath(args.image) if os.path.exists(args.image) else args.image}"
        print(image_hint)
    print(f"推断品类：{brief['category']}")
    print("创意简报：")
    print(f"- 目标人群：{brief['audience']}")
    print(f"- 风格基调：{brief['tone']}")
    print(f"- 画幅策略：{brief['ratio_framing']}")
    print(f"- 趋势方向：{brief['trend_direction']}")
    print(f"- 情绪钩子：{brief['emotional_hook']}")
    print(f"- 视觉钩子：{brief['visual_hook']}")
    print(f"- 场景方向：{brief['scene_direction']}")
    print(f"- 动态语言：{brief['motion_language']}")
    print(f"- 平台侧重：{brief['platform_style']}")
    print(f"- 转化策略：{brief['conversion_strategy']}")
    print(f"- 物理约束：{brief['physics_rules']}")
    print("两段脚本：")
    print(f"- 创意主张：{storyboard['creative_thesis']}")
    print(f"- 叙事衔接：{storyboard['narrative_handoff']}")
    print(f"- 第一段：{storyboard['segment_1']['purpose']} | 旁白思路：{storyboard['segment_1']['spoken_copy']}")
    print(f"  开场景别：{storyboard['segment_1']['opening_shot']} | 中段：{storyboard['segment_1']['middle_shot']} | 收尾：{storyboard['segment_1']['ending_shot']}")
    print(f"- 第二段：{storyboard['segment_2']['purpose']} | 旁白思路：{storyboard['segment_2']['spoken_copy']}")
    print(f"  开场景别：{storyboard['segment_2']['opening_shot']} | 中段：{storyboard['segment_2']['middle_shot']} | 收尾：{storyboard['segment_2']['ending_shot']}")
    print("提示词草案：")
    print(prompt)


if __name__ == "__main__":
    main()
