#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Generate images-plan.md for an OPC community writer task.

Usage:
  generate-images-plan.sh --dir /path/to/task [options]

Options:
  --dir PATH          Task directory
  --topic TEXT        Article topic override
  --column TEXT       Column override
  --force             Overwrite an existing images-plan.md
  -h, --help          Show this help
EOF
}

DIR_PATH=""
TOPIC=""
COLUMN=""
FORCE=0

while [ $# -gt 0 ]; do
  case "$1" in
    --dir)
      DIR_PATH="${2:-}"
      shift 2
      ;;
    --topic)
      TOPIC="${2:-}"
      shift 2
      ;;
    --column)
      COLUMN="${2:-}"
      shift 2
      ;;
    --force)
      FORCE=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [ -z "$DIR_PATH" ]; then
  usage >&2
  exit 1
fi

DIR_PATH="$(cd "$DIR_PATH" && pwd)"
ARTICLE_PATH="$DIR_PATH/article.md"
PLAN_PATH="$DIR_PATH/images-plan.md"

if [ ! -d "$DIR_PATH" ]; then
  echo "Missing task directory: $DIR_PATH" >&2
  exit 1
fi

if [ -f "$PLAN_PATH" ] && [ "$FORCE" -ne 1 ]; then
  echo "images-plan.md already exists: $PLAN_PATH" >&2
  echo "Use --force to overwrite." >&2
  exit 1
fi

if [ -z "$TOPIC" ] && [ -f "$ARTICLE_PATH" ]; then
  TOPIC="$(sed -nE 's/^title:[[:space:]]*(.+)$/\1/p' "$ARTICLE_PATH" | head -n 1 | sed -E 's/^["'"'"']|["'"'"']$//g')"
fi

if [ -z "$COLUMN" ] && [ -f "$ARTICLE_PATH" ]; then
  COLUMN="$(sed -nE 's/^column:[[:space:]]*(.+)$/\1/p' "$ARTICLE_PATH" | head -n 1 | sed -E 's/^["'"'"']|["'"'"']$//g')"
fi

if [ -z "$TOPIC" ]; then
  TOPIC="[文章标题]"
fi

if [ -z "$COLUMN" ]; then
  COLUMN="OPC政策与实操"
fi

cat <<EOF >"$PLAN_PATH"
# Images Plan

## Global Rules
- article_topic: $TOPIC
- column: $COLUMN
- audience: 微信公众号中文读者 + 小红书读者
- language: zh-CN
- text_policy: 核心标题和面向读者的说明文字必须使用简体中文
- default_image_model: gemini-3.1-flash-image-preview
- english_allowed: abbreviations-only
- abbreviation_policy: OPC、AI 等可保留，但核心说明文字必须中文
- prompt_generation_policy: 优先调用专业生图 skill 生成 prompt，不在此文件中写死最终 prompt

## Image 1
- role: cover
- placement: article header
- goal: 用中文标题概括主题并提升点击率
- ratio: 2.35:1
- recommended_skill: baoyu-cover-image
- default_model: gemini-3.1-flash-image-preview
- language_requirement: 核心标题文字必须为简体中文；专业缩写可保留
- visual_direction: editorial / framework / business
- prompt_status: pending
- final_prompt: [待生成]
- output: imgs/cover.png

## Image 2
- role: inline-framework
- placement: 问题切入或关键判断后
- goal: 解释判断框架或路径
- ratio: 3:4
- ratio_rule: 信息密度高可改为 9:16；不要 16:9
- recommended_skill: baoyu-article-illustrator
- default_model: gemini-3.1-flash-image-preview
- language_requirement: 核心标签和说明文字必须为简体中文；专业缩写可保留
- visual_direction: framework / flowchart / comparison
- prompt_status: pending
- final_prompt: [待生成]
- output: imgs/figure-1.png

## Image 3
- role: inline-support
- placement: 案例或路径拆解后
- goal: 展示对比、流程或时间线
- ratio: 9:16
- ratio_rule: 内容较少可改为 3:4 或 1:1；不要 16:9
- recommended_skill: baoyu-article-illustrator 或 baoyu-infographic
- default_model: gemini-3.1-flash-image-preview
- language_requirement: 核心标签和说明文字必须为简体中文；专业缩写可保留
- visual_direction: timeline / comparison / infographic
- prompt_status: pending
- final_prompt: [待生成]
- output: imgs/figure-2.png

## Image 4
- role: xhs-series
- placement: xhs header
- goal: 为小红书派生稿生成更适合平台传播的图组或首图
- ratio: 3:4
- ratio_rule: 也可使用 1:1；不要 16:9
- recommended_skill: baoyu-xhs-images
- default_model: gemini-3.1-flash-image-preview
- language_requirement: 核心标题文字必须为简体中文；专业缩写可保留
- visual_direction: knowledge-card / checklist / pro-summary
- prompt_status: pending
- final_prompt: [待生成]
- output: imgs/xhs-cover.png
EOF

echo "Generated images plan: $PLAN_PATH"
