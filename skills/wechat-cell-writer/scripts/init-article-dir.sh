#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Initialize a WeChat article workspace.

Usage:
  init-article-dir.sh --topic "NK细胞" [options]

Options:
  --topic TEXT         Topic or working title
  --column TEXT        Column name
  --author TEXT        Author name
  --root PATH          Articles root directory
  --date YYYY-MM-DD    Date suffix and frontmatter date
  --task-name TEXT     Override generated task directory name
  --force              Overwrite existing scaffold files
  --print-path-only    Print only the created directory path
  -h, --help           Show this help
EOF
}

trim() {
  printf '%s' "$1" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//'
}

expand_home() {
  local path="$1"
  case "$path" in
    "~") printf '%s\n' "$HOME" ;;
    "~/"*) printf '%s\n' "$HOME/${path#~/}" ;;
    *) printf '%s\n' "$path" ;;
  esac
}

slugify() {
  local input="$1"
  input="$(printf '%s' "$input" | tr '\r\n' '  ' | sed -E 's#[/\\:]+#-#g; s/[[:space:]]+/-/g; s/-+/-/g; s/^-+//; s/-+$//')"
  if [ -z "$input" ]; then
    input="article"
  fi
  printf '%s\n' "$input"
}

write_if_needed() {
  local target="$1"
  local force_flag="$2"
  local content="$3"

  if [ -f "$target" ] && [ "$force_flag" -ne 1 ]; then
    return 1
  fi

  printf '%s' "$content" >"$target"
  return 0
}

TOPIC=""
COLUMN=""
AUTHOR=""
ROOT=""
TASK_DATE="$(date +%Y-%m-%d)"
TASK_NAME=""
FORCE=0
PRINT_PATH_ONLY=0

while [ $# -gt 0 ]; do
  case "$1" in
    --topic)
      TOPIC="${2:-}"
      shift 2
      ;;
    --column)
      COLUMN="${2:-}"
      shift 2
      ;;
    --author)
      AUTHOR="${2:-}"
      shift 2
      ;;
    --root)
      ROOT="${2:-}"
      shift 2
      ;;
    --date)
      TASK_DATE="${2:-}"
      shift 2
      ;;
    --task-name)
      TASK_NAME="${2:-}"
      shift 2
      ;;
    --force)
      FORCE=1
      shift
      ;;
    --print-path-only)
      PRINT_PATH_ONLY=1
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

EXTEND_FILE="$HOME/.baoyu-skills/wechat-cell-writer/EXTEND.md"
if [ -f "$EXTEND_FILE" ]; then
  while IFS= read -r raw_line; do
    line="$(trim "$raw_line")"
    case "$line" in
      ""|\#*) continue ;;
      *:*)
        key="$(trim "${line%%:*}")"
        value="$(trim "${line#*:}")"
        case "$key" in
          default_author)
            if [ -z "$AUTHOR" ]; then AUTHOR="$value"; fi
            ;;
          default_column)
            if [ -z "$COLUMN" ]; then COLUMN="$value"; fi
            ;;
          articles_root)
            if [ -z "$ROOT" ]; then ROOT="$value"; fi
            ;;
        esac
        ;;
    esac
  done <"$EXTEND_FILE"
fi

if [ -z "$TOPIC" ]; then
  TOPIC="未命名选题"
fi

if [ -z "$COLUMN" ]; then
  COLUMN="科研前沿解读"
fi

if [ -z "$AUTHOR" ]; then
  AUTHOR="细胞小境"
fi

if [ -z "$ROOT" ]; then
  ROOT="$HOME/gongzhonghao/articles"
fi
ROOT="$(expand_home "$ROOT")"

if [ -z "$TASK_NAME" ]; then
  TASK_NAME="$(slugify "$TOPIC")-$TASK_DATE"
fi

ARTICLE_DIR="$ROOT/$TASK_NAME"
mkdir -p "$ARTICLE_DIR/imgs"

ARTICLE_TITLE="$TOPIC"
if [ "$ARTICLE_TITLE" = "未命名选题" ]; then
  ARTICLE_TITLE="[文章标题]"
fi

read -r -d '' ARTICLE_TEMPLATE <<EOF || true
---
title: $ARTICLE_TITLE
author: $AUTHOR
date: $TASK_DATE
column: $COLUMN
tags: []
coverImage: ./imgs/cover.png
images:
  - ./imgs/figure-1.png
  - ./imgs/figure-2.png
---

# $ARTICLE_TITLE

> [摘要/引言，100字以内]

## [小标题1]

[正文内容]

![图1：核心概念图解](./imgs/figure-1.png)
*图1：[图片说明文字]*

## [小标题2]

[正文内容]

![图2：数据/流程展示](./imgs/figure-2.png)
*图2：[图片说明文字]*

## [小标题3：核心论文解读]

[围绕核心论文展开解读]

![论文截图](./imgs/paper-1.png)
*图：核心论文摘要截图（来源：[期刊] [年份]）*

---

## 📖 参考资料
1. [期刊/媒体/政策来源，禁止 URL]
EOF

read -r -d '' RESEARCH_TEMPLATE <<EOF || true
# Research Notes

## Topic
- Working title: $TOPIC
- Column: $COLUMN
- Date: $TASK_DATE

## Academic Papers
- Title:
  Journal:
  Year:
  DOI:
  URL:
  Screenshot priority: High / Medium / Low

## Medical Media
- Source:
  Date:
  URL:
  Notes:

## Competitor Content
- Account:
  Title:
  Angle:
  Notes:

## Policy Updates
- Agency:
  Date:
  Document:
  Notes:
EOF

read -r -d '' TOPICS_TEMPLATE <<EOF || true
# Topic Candidates

## Candidate 1
- Column: $COLUMN
- Why:
- Sources:
- Estimated length:

## Candidate 2
- Column:
- Why:
- Sources:
- Estimated length:

## Candidate 3
- Column:
- Why:
- Sources:
- Estimated length:
EOF

read -r -d '' IMAGES_PLAN_TEMPLATE <<EOF || true
# Images Plan

## Global Rules
- article_topic: $ARTICLE_TITLE
- column: $COLUMN
- audience: 微信公众号中文读者
- language: zh-CN
- text_policy: 核心内容和面向读者的说明文字必须使用简体中文
- english_allowed: abbreviations-only
- abbreviation_policy: 专业术语、英文名词和字母缩写可保留（如 CAR-T、NK、TIL、iPSC），但核心说明文字必须中文
- prompt_generation_policy: 优先调用专业生图 skill 生成 prompt，不在此文件中写死最终 prompt

## Image 1
- role: cover
- placement: article header
- goal: 用中文标题概括主题并提升点击率
- ratio: 2.35:1
- recommended_skill: baoyu-cover-image
- language_requirement: 核心标题文字必须为简体中文；专业缩写可保留
- visual_direction: 根据栏目选择主色和情绪；适合微信公众号封面
- prompt_status: pending
- final_prompt: [待生成]
- output: imgs/cover.png

## Image 2
- role: inline-concept
- placement: 小标题1后
- goal: 解释核心概念或机制
- ratio: 3:4
- ratio_rule: 信息密度高可改为 9:16；概念单一可改为 1:1；不要 16:9
- recommended_skill: baoyu-article-illustrator
- language_requirement: 核心标签和说明文字必须为简体中文；专业缩写可保留
- visual_direction: flowchart / framework / infographic 任选其一
- prompt_status: pending
- final_prompt: [待生成]
- output: imgs/figure-1.png

## Image 3
- role: inline-support
- placement: 小标题2后
- goal: 展示数据、流程、对比或时间线
- ratio: 9:16
- ratio_rule: 内容较少可改为 3:4 或 1:1；不要 16:9
- recommended_skill: baoyu-article-illustrator 或 baoyu-infographic
- language_requirement: 面向读者的核心文字必须为简体中文；专业缩写可保留
- visual_direction: timeline / comparison / infographic 任选其一
- prompt_status: pending
- final_prompt: [待生成]
- output: imgs/figure-2.png

## Image 4
- role: paper-screenshot
- placement: 核心论文引用附近
- goal: 提升论文引用可信度
- ratio: source-native
- recommended_skill: wechat-cell-writer screenshot-paper.ts
- language_requirement: 保留原始论文页面内容，无需二次加英文说明
- visual_direction: 仅截核心 1-2 篇论文，优先顶刊
- prompt_status: not_applicable
- final_prompt: [不适用]
- output: imgs/paper-1.png
EOF

CREATED=0
PRESERVED=0

if write_if_needed "$ARTICLE_DIR/article.md" "$FORCE" "$ARTICLE_TEMPLATE"; then
  CREATED=$((CREATED + 1))
else
  PRESERVED=$((PRESERVED + 1))
fi

if write_if_needed "$ARTICLE_DIR/research.md" "$FORCE" "$RESEARCH_TEMPLATE"; then
  CREATED=$((CREATED + 1))
else
  PRESERVED=$((PRESERVED + 1))
fi

if write_if_needed "$ARTICLE_DIR/topics.md" "$FORCE" "$TOPICS_TEMPLATE"; then
  CREATED=$((CREATED + 1))
else
  PRESERVED=$((PRESERVED + 1))
fi

if write_if_needed "$ARTICLE_DIR/images-plan.md" "$FORCE" "$IMAGES_PLAN_TEMPLATE"; then
  CREATED=$((CREATED + 1))
else
  PRESERVED=$((PRESERVED + 1))
fi

if [ "$PRINT_PATH_ONLY" -eq 1 ]; then
  printf '%s\n' "$ARTICLE_DIR"
  exit 0
fi

cat <<EOF
Article directory: $ARTICLE_DIR
Created scaffold files: $CREATED
Preserved existing files: $PRESERVED

Files:
- $ARTICLE_DIR/research.md
- $ARTICLE_DIR/topics.md
- $ARTICLE_DIR/article.md
- $ARTICLE_DIR/images-plan.md
- $ARTICLE_DIR/imgs/
EOF
