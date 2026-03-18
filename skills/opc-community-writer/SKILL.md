---
name: opc-community-writer
description: >
  Create WeChat Official Account articles and Xiaohongshu derivatives for an OPC
  (one-person company) community. Researches policy updates, practical guides,
  legal boundaries, cases, and competitor content to produce compliant,
  community-growth-oriented content for potential and existing OPC founders.
  Use when the user wants OPC articles, 一人公司内容, 社群招募内容, 公众号文章,
  小红书改写, 政策解读, 创业指南, or 案例拆解.
allowed-tools:
  - Bash(npm *)
  - Bash(npx *)
  - Bash(bun *)
  - Bash(node *)
---

# OPC Community Writer

A skill for producing high-signal content that helps an OPC community attract new members through policy interpretation, practical guidance, and case-based writing.

## First-Time Setup

Run once before using the workflow:

```bash
bash ~/.agents/skills/opc-community-writer/scripts/setup.sh
```

## Language

Match the user's language. Chinese requests should produce Chinese output unless the user explicitly asks otherwise.

## Positioning

This skill is not a generic entrepreneurship writer. It is a growth-oriented content engine for an OPC community.

### Target Audience

- People exploring a shift from employment, freelancing, or side projects into OPC
- People already operating a one-person company and looking for cases, peers, and methods

### Default Content Goal

- Help readers understand OPC
- Give them a usable frame for decisions
- Show real paths and tradeoffs
- Softly invite them into the community

### Article Specifications

- WeChat article length: 1500-3000 words
- Xiaohongshu derivative: short-form rewrite based on the same argument
- Style: dense, clear, opinionated but non-hype
- Images: cover + 2 inline images for the article, optional XHS image series or cover image
- Cover: 900×383px, Chinese title text, suitable for entrepreneurial/business topics

## Reference Map

Read only what is needed for the current step:

- Step 1 检索： [references/search-queries.md](references/search-queries.md), [references/output-format.md](references/output-format.md)
- Step 2 选题： `topics.md` scaffold, plus [references/column-templates.md](references/column-templates.md)
- Step 3 写主稿： [references/title-guidelines.md](references/title-guidelines.md), [references/citation-format.md](references/citation-format.md), [references/article-template.md](references/article-template.md)
- Step 4 派生小红书： [references/xhs-template.md](references/xhs-template.md)
- Step 5 配图： [references/image-generation-guide.md](references/image-generation-guide.md), [references/cover-image-guidelines.md](references/cover-image-guidelines.md)
- Step 6 校验： [references/review-checklist.md](references/review-checklist.md), [references/compliance-checklist.md](references/compliance-checklist.md)
- Step 7 发布： [references/publishing-guide.md](references/publishing-guide.md)
- 排版推荐：使用 `opc-markdown-to-html` 生成团队自维护 HTML 模板

## Three Default Columns

### 1. OPC政策与实操

Interpret official policies, application routes, and operational implications.

### 2. OPC创业指南

Explain key choices, frameworks, and practical tradeoffs for one-person companies.

### 3. OPC案例拆解

Break down traceable cases and extract methods instead of hero stories.

## Complete Workflow

```text
Step 0  创建任务文件夹并生成 article.md / xhs.md / research.md / topics.md / images-plan.md
Step 1  检索政策、办事指南、法律边界、案例、平台内容
Step 2  基于社群增长目标给出 3-5 个选题
Step 3  写公众号主稿 article.md
Step 4  基于主稿生成 xhs.md
Step 5  生成封面、正文配图和小红书图组建议，并插入 article.md
Step 6  运行 research / article / xhs / images 校验
Step 7  用户确认后发布公众号；小红书 v1 仅输出内容稿，不发布
```

## Critical Rules

- `article.md` 和 `xhs.md` 都禁止 URL
- 软 CTA 只放结尾，不在正文频繁招募
- 不承诺收益、接单、补贴结果
- 不输出个性化法律或税务判断
- 涉及政策、注册、税务、补贴时，必须标注日期和地区
- 案例必须可追溯到原始来源或可靠报道

## Working Folder

Default structure:

```text
~/gongzhonghao/opc-community/{task-name}/
├── article.md
├── xhs.md
├── research.md
├── topics.md
├── images-plan.md
└── imgs/
    ├── cover.png
    ├── figure-1.png
    ├── figure-2.png
    └── xhs-cover.png
```

## Workflow Commands

```bash
node ~/.agents/skills/opc-community-writer/scripts/run-workflow.js --step init --topic "为什么 AI 时代一人公司值得重新理解"
node ~/.agents/skills/opc-community-writer/scripts/run-workflow.js --step status --dir "$ARTICLE_DIR"
node ~/.agents/skills/opc-community-writer/scripts/run-workflow.js --step plan-images --dir "$ARTICLE_DIR"
node ~/.agents/skills/opc-community-writer/scripts/run-workflow.js --step validate --dir "$ARTICLE_DIR"
bash ~/.agents/skills/opc-community-writer/scripts/sanitize-article.sh --dir "$ARTICLE_DIR"
```
