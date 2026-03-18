#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Initialize an OPC community article workspace.

Usage:
  init-article-dir.sh --topic "一人公司" [options]

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
    input="opc-article"
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

EXTEND_FILE="$HOME/.baoyu-skills/opc-community-writer/EXTEND.md"
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
  COLUMN="OPC政策与实操"
fi

if [ -z "$AUTHOR" ]; then
  AUTHOR="OPC成员社群"
fi

if [ -z "$ROOT" ]; then
  ROOT="$HOME/gongzhonghao/opc-community"
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
summary: [一句话摘要，明确读者会看到什么判断]
date: $TASK_DATE
column: $COLUMN
tags: [OPC, 一人公司]
coverImage: ./imgs/cover.png
images:
  - ./imgs/figure-1.png
  - ./imgs/figure-2.png
---

# $ARTICLE_TITLE

> [一句话摘要，明确读者会看到什么判断]

## 问题切入

[从读者的真实困惑开场]

## 政策/现象背景

- 政策时间：$TASK_DATE
- 适用地区：全国
- 适用对象：准备转型者 / 已在做 OPC 的人

[解释这件事为什么值得看]

![图1：框架图或路径图](./imgs/figure-1.png)
*图1：[图片说明文字]*

## 关键判断

[给出清晰判断和边界，不做收益承诺]

> 判断先行：如果这篇是政策或注册主题，尽量用 1 句话把“适用对象 + 结论边界”说清楚。

## 案例或路径拆解

[拆一个案例，或者给出办事路径/决策路径]

![图2：对比图或时间线](./imgs/figure-2.png)
*图2：[图片说明文字]*

## 对不同阶段 OPC 的启发

- 对准备转型的人：
- 对已经在做的人：

## 关键信息对照表

| 维度 | 结论 | 适用人群 |
|------|------|----------|
| [维度 1] | [一句话结论] | [谁适用] |
| [维度 2] | [一句话结论] | [谁适用] |

## 如果你想继续交流

[如果你也在观察 OPC、正试着把个人能力产品化，或者已经开始做一人公司，欢迎来社群继续交流。这里更适合讨论案例、方法论和实操细节，不承诺结果，只分享真实路径和经验。]

---

## 📖 参考资料
1. [机构/媒体/案例名]，[日期/文号]。
EOF

read -r -d '' XHS_TEMPLATE <<EOF || true
# [小红书主标题]

## 标题候选
1. [标题1]
2. [标题2]
3. [标题3]

## 适用人群
- 准备转型的人
- 已经在做 OPC 的人

## 开头钩子
[2-4 句，直接点出困惑和判断]

## 正文
### 卡片 1
[一句结论 + 一句解释]

### 卡片 2
[政策/现象背景，保留日期和地区]

### 卡片 3
[关键判断]

### 卡片 4
[案例或路径]

### 卡片 5
[给不同阶段读者的启发]

## 标签
#OPC #一人公司 #个人创业

## 软 CTA
[如果你也在做或准备做 OPC，欢迎来社群继续交流案例、方法论和实操细节。]
EOF

read -r -d '' RESEARCH_TEMPLATE <<EOF || true
# Research Notes

## Topic
- Working title: $TOPIC
- Column: $COLUMN
- Date: $TASK_DATE

## 政策法规
- Source type: 官方政策
  发布机构:
  发布时间:
  适用地区:
  适用对象:
  核心结论:
  URL:
  对社群读者的价值:
  风险提醒:
  可转化角度:

## 办事路径
- Source type: 官方办事指南
  发布机构:
  发布时间:
  适用地区:
  适用对象:
  办理路径:
  关键材料/步骤:
  URL:
  对社群读者的价值:
  风险提醒:
  可转化角度:

## 法律边界
- Source type: 法院解读 / 法治文章 / 监管口径
  发布机构:
  发布时间:
  适用地区:
  适用对象:
  核心边界:
  URL:
  对社群读者的价值:
  风险提醒:
  可转化角度:

## 创业案例
- Source type: 创业案例 / 媒体报道
  案例主体:
  发布时间:
  地区:
  案例摘要:
  可验证事实:
  URL:
  对社群读者的价值:
  风险提醒:
  可转化角度:

## 平台内容观察
- Platform:
  Account:
  Title:
  Date:
  Angle:
  Notes:
  URL:
EOF

read -r -d '' TOPICS_TEMPLATE <<EOF || true
# Topic Candidates

## Candidate 1
- Layer: 认知层 / 决策层 / 转化层
- Column: $COLUMN
- Why:
- Sources:
- CTA angle:

## Candidate 2
- Layer:
- Column:
- Why:
- Sources:
- CTA angle:

## Candidate 3
- Layer:
- Column:
- Why:
- Sources:
- CTA angle:
EOF

read -r -d '' IMAGES_PLAN_TEMPLATE <<EOF || true
# Images Plan

## Global Rules
- article_topic: $ARTICLE_TITLE
- column: $COLUMN
- audience: 微信公众号中文读者 + 小红书读者
- language: zh-CN
- text_policy: 核心标题和面向读者的说明文字必须使用简体中文
- english_allowed: abbreviations-only
- abbreviation_policy: OPC、AI 等可保留，但核心说明文字必须中文
- prompt_generation_policy: 优先调用专业生图 skill 生成 prompt，不在此文件中写死最终 prompt

## Image 1
- role: cover
- placement: article header
- goal: 用中文标题概括主题并提升点击率
- ratio: 2.35:1
- recommended_skill: baoyu-cover-image
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
- language_requirement: 核心标题文字必须为简体中文；专业缩写可保留
- visual_direction: knowledge-card / checklist / pro-summary
- prompt_status: pending
- final_prompt: [待生成]
- output: imgs/xhs-cover.png
EOF

CREATED=0
PRESERVED=0

for file in article.md xhs.md research.md topics.md images-plan.md; do
  case "$file" in
    article.md) CONTENT="$ARTICLE_TEMPLATE" ;;
    xhs.md) CONTENT="$XHS_TEMPLATE" ;;
    research.md) CONTENT="$RESEARCH_TEMPLATE" ;;
    topics.md) CONTENT="$TOPICS_TEMPLATE" ;;
    images-plan.md) CONTENT="$IMAGES_PLAN_TEMPLATE" ;;
  esac

  if write_if_needed "$ARTICLE_DIR/$file" "$FORCE" "$CONTENT"; then
    CREATED=$((CREATED + 1))
  else
    PRESERVED=$((PRESERVED + 1))
  fi
done

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
- $ARTICLE_DIR/xhs.md
- $ARTICLE_DIR/images-plan.md
- $ARTICLE_DIR/imgs/
EOF
