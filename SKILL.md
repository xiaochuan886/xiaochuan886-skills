---
name: wechat-cell-writer
description: Automatically generates WeChat Official Account articles about cell therapy. Searches latest research, industry news, and competitor content to create engaging, compliant articles (1500-3000 words) for general readers. Supports three columns: Research Frontiers (科研前沿解读), Cell Science Popularization (细胞科普系列), and Health Tips (健康管家Tips). Use when user wants to create cell therapy articles, write WeChat articles about cells, or mentions "写文章", "细胞文章", "公众号文章".
---

# WeChat Cell Article Writer

A skill for automatically generating engaging, compliant WeChat Official Account articles about cell therapy for general readers.

## Language

**Match user's language**: Respond in the same language the user uses. If user writes in Chinese, respond in Chinese. If user writes in English, respond in English.

## Overview

This skill helps create professional yet accessible articles about cell therapy for WeChat Official Accounts. It follows a complete workflow from topic research to publication.

### Target Audience
- General readers (non-professional background)
- People interested in health and cell therapy
- Potential customers of cell storage services

### Article Specifications
- **Length**: 1500-3000 words
- **Style**: Professional but accessible (专业但通俗)
- **Brand**: Pure science popularization, no commercial植入
- **Images**: 3+ images per article (cover + 2+ inline)
- **Cover**: 900×383px (2.35:1), safe zone 383×383px, with Chinese title text

## Reference Map

按任务阶段优先阅读这些文件：
- Step 1 检索： [references/search-queries.md](references/search-queries.md), [references/output-format.md](references/output-format.md)
- Step 2 选题： 使用 `topics.md` 骨架即可，必要时回看 [references/column-templates.md](references/column-templates.md)
- Step 3 写作： [references/title-guidelines.md](references/title-guidelines.md), [references/citation-format.md](references/citation-format.md), [references/article-template.md](references/article-template.md), [references/column-templates.md](references/column-templates.md)
- Step 4 配图： [references/image-generation-guide.md](references/image-generation-guide.md), [references/cover-image-guidelines.md](references/cover-image-guidelines.md), [references/paper-screenshot-guide.md](references/paper-screenshot-guide.md)
- Step 5 校验： [references/review-checklist.md](references/review-checklist.md), [references/compliance-checklist.md](references/compliance-checklist.md)
- Step 6 发布： [references/publishing-guide.md](references/publishing-guide.md)

---

## Three Article Columns

### 1. Research Frontiers (科研前沿解读)
Interpret latest research papers and clinical progress.

**Title Formula**: `「最新研究」` + Topic + Significance
**Example**: `「最新研究」TIL疗法攻克实体瘤，肺癌患者迎来新曙光`

### 2. Cell Science Series (细胞科普系列)
Explain cell types and their functions.

**Title Formula**: Cell Type + Core Function + User Value
**Example**: `NK细胞：你身体里的"天然杀手"，如何守护健康？`

### 3. Health Tips (健康管家Tips)
Practical health advice for readers.

**Title Formula**: Problem Scenario + Solution
**Example**: `免疫力下降怎么办？科学提升免疫力的5个方法`

---


## Complete Workflow

```
┌─────────────────────────────────────────────────────────────┐
│  Step 0: 创建任务文件夹                                       │
│    └─ mkdir {标题关键词}-{日期}/imgs/                         │
│                          ↓                                   │
│  Step 1: Information Retrieval                               │
│    ├─ Academic papers (PubMed, Nature, Cell, etc.)          │
│    ├─ Medical media (DXY, Yxj.org.cn, etc.)                 │
│    ├─ Competitor articles (WeChat accounts)                  │
│    └─ Policy updates (NMPA, CDE, NHC)                        │
│    → 保存到: {文件夹}/research.md                             │
│    ⚠️ 如引用论文，记录论文URL用于后续截图                       │
│                          ↓                                   │
│  Step 2: Topic Recommendation                                │
│    └─ Present 3-5 topic suggestions with summaries           │
│    → 保存到: {文件夹}/topics.md                               │
│                          ↓                                   │
│  Step 3: Article Writing                                     │
│    ├─ Generate attractive but compliant title                │
│    ├─ Write article following column template                │
│    ├─ Include proper citations                               │
│    └─ ⚠️ 在正文中插入图片占位符（见下方规则）                    │
│    → 保存到: {文件夹}/article.md                              │
│                          ↓                                   │
│  Step 4: Image Generation (3+张配图)                          │
│    ├─ ⛔ Step 4.1: 阅读 references/image-generation-guide.md │
│    ├─ Step 4.2: 为每张图片选择设计参数(5维度/Type×Style)      │
│    ├─ Step 4.3: 根据 images-plan.md 调用专业生图 skill 生成 Prompt │
│    ├─ Step 4.4: 生成图片                                      │
│    │   ├─ 封面图 (5维度) → imgs/cover.png                     │
│    │   ├─ 配图1 (Type×Style) → imgs/figure-1.png             │
│    │   ├─ 配图2 (Type×Style) → imgs/figure-2.png             │
│    │   └─ 论文截图 → imgs/paper-*.png                         │
│    └─ ⚠️ 更新 article.md 插入所有图片引用                     │
│                          ↓                                   │
│  Step 5: Pre-Publish Checklist ⚠️ 必须执行                    │
│    ├─ 检查：封面图是否存在？                                   │
│    ├─ 检查：正文是否有图片引用（非仅 frontmatter）？           │
│    ├─ 检查：如引用论文，是否有论文截图？                        │
│    └─ 检查：所有图片文件是否存在？                             │
│                          ↓                                   │
│  Step 6: Review & Publish                                    │
│    ├─ User reviews and approves                              │
│    └─ Publish via baoyu-post-to-wechat                       │
└─────────────────────────────────────────────────────────────┘
```

---

## ⚠️ CRITICAL: 图片插入规则

硬规则：
- 图片必须插入 **正文**，不能只写 frontmatter
- 正文至少应有 2 张配图引用
- 论文截图必须插在对应论文引用附近

快速检查：
```bash
grep -n "^\!\[" article.md
```

模板和示例见 [references/article-template.md](references/article-template.md)。

---

## ⚠️ CRITICAL: 论文截图规则

硬规则：
- 只要文章引用论文，就必须有论文截图
- 默认保留 1-2 篇核心论文截图
- 优先选择顶刊
- `research.md` 中必须标记 `Screenshot priority`

详细规则见 [references/paper-screenshot-guide.md](references/paper-screenshot-guide.md)。

---

## Step 0: 创建任务文件夹

**每个任务开始前，首先创建独立的工作文件夹。**

### 命名规则

```bash
# 格式: {文章标题关键词}-{YYYY-MM-DD}
# 示例
car-t-anti-aging-2026-03-04
nk-cell-immunity-2026-03-05
干细胞存储指南-2026-03-06
```

### 创建命令

```bash
# 推荐：使用初始化脚本创建标准工作目录
~/.agents/skills/wechat-cell-writer/scripts/init-article-dir.sh \
  --topic "CAR-T抗衰老" \
  --date "$(date +%Y-%m-%d)"

# 或使用 workflow runner
node ~/.agents/skills/wechat-cell-writer/scripts/run-workflow.js \
  --step init \
  --topic "CAR-T抗衰老"
```

### 文件夹结构

```
~/gongzhonghao/articles/{任务文件夹}/
├── article.md                    # 最终文章 (Markdown)
├── article.html                  # 发布时自动生成的 HTML
├── research.md                   # 信息检索结果
├── topics.md                     # 选题推荐记录
├── images-plan.md                # 图片任务单（中文受众 / 比例 / skill 路由）
├── imgs/
│   ├── cover.png                 # 封面图 (900×383px)
│   ├── figure-1.png              # 配图1 (核心概念)
│   ├── figure-2.png              # 配图2 (数据/流程)
│   └── paper-*.png               # 论文截图 (引用论文时必需)
└── publish-info.json             # 发布信息记录 (可选)
```

---

## Step 1: Information Retrieval

### Information Sources (Priority Order)

| Priority | Source Type | Examples | What to Extract |
|----------|-------------|----------|-----------------|
| 1 | Academic Papers | PubMed, Nature, Cell, Lancet | Research findings, clinical data, DOI, **URL for screenshot** |
| 2 | Medical Media | 丁香园, 医学界, 健康界 | News interpretation, expert opinions |
| 3 | Competitor Articles | WeChat accounts, Toutiao | Hot topics, writing styles |
| 4 | Policy Updates | NMPA, CDE, 卫健委 | Regulatory changes, approvals |

→ **搜索模式**: [references/search-queries.md](references/search-queries.md)
→ **输出格式**: [references/output-format.md](references/output-format.md)

---

## Step 2: Topic Recommendation

基于 `research.md` 推荐 3-5 个选题，写入 `topics.md`。格式参考工作目录骨架即可。

---

## Step 3: Article Writing

写作时只保留以下硬约束：
- 标题准确、不过度承诺
- 引用可追溯，但 `article.md` 禁止 URL
- 正文必须有图片引用
- 模板默认带论文截图块

详细规则见：
- [references/title-guidelines.md](references/title-guidelines.md)
- [references/citation-format.md](references/citation-format.md)
- [references/article-template.md](references/article-template.md)
- [references/column-templates.md](references/column-templates.md)

---

## Step 4: Image Generation (3+张配图)

### 4.5 引用图补充（合规优先，推荐）

在 Cell Writer 的“自制图”之外，可以补充 1-3 张**引用科普图**来提升质感（例如：显微图、机制示意图）。

使用配套 skill：`wechat-safe-science-images`
- 来源白名单：默认仅 Wikimedia Commons
- 许可闸门：只允许 Public Domain/CC0/CC BY/CC BY-SA，拒绝 NC/ND/未知
- 输出：下载到 `imgs/refs/` + `image-manifest.json` + `image-credits.md`

工作流命令（建议在写完 article.md 初稿后执行）：
```bash
node ~/.agents/skills/wechat-cell-writer/scripts/run-workflow.js \
  --step fetch-ref-images --dir "$ARTICLE_DIR" --limit 3
```

署名策略（按你的要求，默认启用 A，并按最新约定更新）：
- **对读者的披露**：在每张引用图下方追加一句简短说明（不带 URL），例如：
  - `*图源：Wikimedia Commons（公开许可素材，CC BY）。*`
- **内部留档**：完整来源/许可证据链写入 `imgs/refs/image-manifest.json`（可含 URL），不放正文。
- 不再在正文末尾添加“图片来源与授权/图片素材摘要”等大段区块（避免对读者无意义的信息）。


### ⚠️ 重要：生成图片前必须阅读详细指南

**⛔ BLOCKING**: 在生成任何图片之前，必须先阅读 [references/image-generation-guide.md](references/image-generation-guide.md)，按照其中的 **封面带标题规则**、**5维度框架** 和 **Type × Style 矩阵** 构建 prompt。

**不要直接手写简单 prompt！** 应该根据图片类型选择对应的设计框架。

---

### 图片类型与设计框架映射

| 图片类型 | 参考 Skill | 设计框架 | 详细指南章节 |
|----------|------------|----------|--------------|
| **封面图** | `baoyu-cover-image` | 5维度 (Type/Palette/Rendering/Text/Mood) + 带标题封面 | 封面图设计 |
| **配图** | `baoyu-article-illustrator` | Type × Style 矩阵 | 配图设计 |
| **信息图** | `baoyu-infographic` | 21布局 × 20风格 | 信息图设计 |
| **论文截图** | 内置脚本 | 截图工具（核心 1-2 篇） | 论文截图 |

---

### 📋 图片生成流程

**Step 4.1: 阅读详细指南** ⛔ BLOCKING
```bash
# 阅读配图指南，了解 5维度框架 和 Type×Style 矩阵
cat references/image-generation-guide.md

# 检查图片任务单
cat "$ARTICLE_DIR/images-plan.md"
```

**Step 4.2: 先确认 images-plan.md，再为每张图片选择设计参数**

硬规则：
- 先看 `images-plan.md`
- 配图默认只用 `9:16 / 3:4 / 1:1`
- 不使用 `16:9`
- 核心标题、标签、说明文字必须为简体中文
- 专业术语、英文名词和字母缩写可保留

**Step 4.3: 调用专业 skill 生成 Prompt**

优先根据 `images-plan.md` 中的 `recommended_skill` 调用专业生图 skill 生成 prompt：
- 封面图：`baoyu-cover-image`
- 正文概念图：`baoyu-article-illustrator`
- 数据型图片：`baoyu-infographic`
- 论文图：内置截图脚本

`images-plan.md` 只负责图片任务单，不负责写死最终 prompt。

**Step 4.4: 生成图片**

> **详细配图指南**: [references/image-generation-guide.md](references/image-generation-guide.md)
> **论文截图指南**: [references/paper-screenshot-guide.md](references/paper-screenshot-guide.md)

生成命令、prompt 模板和示例统一见 [references/image-generation-guide.md](references/image-generation-guide.md)。

---

## Step 5: Pre-Publish Checklist ⚠️ 必须执行

推荐先运行自动校验脚本，再进行人工复核：

```bash
bash ~/.agents/skills/wechat-cell-writer/scripts/validate-images-plan.sh \
  --dir "$ARTICLE_DIR"

bash ~/.agents/skills/wechat-cell-writer/scripts/validate-research.sh \
  --dir "$ARTICLE_DIR"

bash ~/.agents/skills/wechat-cell-writer/scripts/validate-article.sh \
  --dir "$ARTICLE_DIR"

# 生成无 URL 的发布稿
bash ~/.agents/skills/wechat-cell-writer/scripts/sanitize-article.sh \
  --dir "$ARTICLE_DIR"
```

人工复核清单见 [references/review-checklist.md](references/review-checklist.md)。

---

## Step 6: Review & Publish

发布主题、颜色和命令见 [references/publishing-guide.md](references/publishing-guide.md)。

发布前硬规则：
1. `article.md` 和最终发布稿都不包含 URL
2. 图片已生成且正文已引用
3. 论文截图已控制在 1-2 篇核心论文

---

## Preferences (EXTEND.md)

Users can customize settings via EXTEND.md:

**Location**: `~/.baoyu-skills/wechat-cell-writer/EXTEND.md`

```md
default_author: 细胞小境
default_column: 科研前沿解读
articles_root: ~/gongzhonghao/articles
cover_style: 科技感
cover_ratio: 2.35:1
```

---

## Quick Commands

| Command | Description |
|---------|-------------|
| `node ~/.agents/skills/wechat-cell-writer/scripts/run-workflow.js --step init --topic "NK细胞"` | 初始化任务目录和文章骨架 |
| `node ~/.agents/skills/wechat-cell-writer/scripts/run-workflow.js --step status --dir "$ARTICLE_DIR"` | 查看当前任务状态 |
| `node ~/.agents/skills/wechat-cell-writer/scripts/run-workflow.js --step plan-images --dir "$ARTICLE_DIR"` | 重新生成 images-plan.md |
| `node ~/.agents/skills/wechat-cell-writer/scripts/run-workflow.js --step validate-images --dir "$ARTICLE_DIR"` | 校验 images-plan.md 的中文规则、比例和 skill 路由 |
| `node ~/.agents/skills/wechat-cell-writer/scripts/run-workflow.js --step validate-research --dir "$ARTICLE_DIR"` | 校验 research.md 的结构和核心论文标记 |
| `node ~/.agents/skills/wechat-cell-writer/scripts/run-workflow.js --step validate --dir "$ARTICLE_DIR"` | 运行发布前校验 |
| `node ~/.agents/skills/wechat-cell-writer/scripts/run-workflow.js --step sanitize --dir "$ARTICLE_DIR"` | 生成可发布的无 URL 稿件 |
| `bash ~/.agents/skills/wechat-cell-writer/scripts/validate-article.sh --dir "$ARTICLE_DIR"` | 直接执行校验脚本 |
| `bash ~/.agents/skills/wechat-cell-writer/scripts/validate-images-plan.sh --dir "$ARTICLE_DIR"` | 直接校验 images-plan.md |
| `bash ~/.agents/skills/wechat-cell-writer/scripts/validate-research.sh --dir "$ARTICLE_DIR"` | 直接校验 research.md |
| `bash ~/.agents/skills/wechat-cell-writer/scripts/sanitize-article.sh --dir "$ARTICLE_DIR"` | 直接生成无 URL 的发布稿 |

在 `scripts/` 目录下也可以用 `npm run workflow:*`：
- `npm run workflow:init -- --topic "NK细胞"`
- `npm run workflow:plan-images -- --dir "$ARTICLE_DIR"`
- `npm run workflow:validate-images -- --dir "$ARTICLE_DIR"`
- `npm run workflow:validate-research -- --dir "$ARTICLE_DIR"`
- `npm run workflow:validate-article -- --dir "$ARTICLE_DIR"`
- `npm run workflow:sanitize -- --dir "$ARTICLE_DIR"`

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| No search results | Try broader keywords or different time range |
| Title feels clickbait | Revise to be more accurate and less sensational |
| Content too technical | Add analogies and everyday examples |
| Missing citations | Always note source during retrieval phase |
| Images not matching | 阅读 references/image-generation-guide.md，使用 5维度/Type×Style 框架构建专业 prompt |
| Image prompts too simple | 不要手写简单 prompt，使用模板并根据设计框架选择参数 |
| Publish failed 45166 | Remove external links from article |
| Images not showing in WeChat | Check if images are inserted in markdown body (not just frontmatter) |
| Missing paper screenshots | Generate screenshots for all cited academic papers |
| **WeChat API: credentials not found** | 检查 `~/.baoyu-skills/.env` 文件是否存在，内容格式： `WECHAT_APP_ID=xxx` `WECHAT_APP_SECRET=xxx` |
| **WeChat API: invalid credential** | 在 [微信公众号后台](https://mp.weixin.qq.com) → 开发 → 基本配置 重新获取 AppID 和 AppSecret |
| **Playwright not found** | `cd ~/.agents/skills/wechat-cell-writer/scripts && npx -y bun install` |
| **Chromium browser not found** | `npx -y bun x playwright install chromium` |
| **Gemini image generation fails** | 确保使用 `gemini-3.1-flash-image-preview` 模型，降低 imageSize 到 1K |
| **不确定缺了哪些步骤** | `node ~/.agents/skills/wechat-cell-writer/scripts/run-workflow.js --step status --dir "$ARTICLE_DIR"` |
| **不知道图片该怎么规划** | `node ~/.agents/skills/wechat-cell-writer/scripts/run-workflow.js --step plan-images --dir "$ARTICLE_DIR"` |
| **不确定图片规划是否符合中文受众要求** | `bash ~/.agents/skills/wechat-cell-writer/scripts/validate-images-plan.sh --dir "$ARTICLE_DIR"` |
| **不确定 research 是否够完整** | `bash ~/.agents/skills/wechat-cell-writer/scripts/validate-research.sh --dir "$ARTICLE_DIR"` |
| **发布前不知道哪里不合规** | `bash ~/.agents/skills/wechat-cell-writer/scripts/validate-article.sh --dir "$ARTICLE_DIR"` |
| **需要生成可发布版本** | `bash ~/.agents/skills/wechat-cell-writer/scripts/sanitize-article.sh --dir "$ARTICLE_DIR"` |

### .env 文件位置（按优先级）

```
~/.baoyu-skills/.env          ← 优先使用（用户全局配置）
<项目目录>/.baoyu-skills/.env  ← 项目级配置
```

---

## Related Skills

- `baoyu-cover-image`: 封面图
- `baoyu-article-illustrator`: 正文概念图
- `baoyu-infographic`: 数据型图片
- `baoyu-image-gen`: 底层出图
- `baoyu-post-to-wechat`: 发布

## Current Limits

- `zai-mcp-server` 当前不在本会话可用 skill 列表中，不能直接接入自动截图验图链路
- 当前论文截图校验使用页面内容启发式检测：Cloudflare、安全验证、cookies 遮挡、缺少正文标题
- 如检测到异常且提供 `--pubmed-url`，截图脚本会自动回退到 PubMed 页面再截一次

---

## References

| 文件 | 内容 |
|------|------|
| [title-guidelines.md](references/title-guidelines.md) | 标题写作指南 |
| [citation-format.md](references/citation-format.md) | 引用格式规范 |
| [column-templates.md](references/column-templates.md) | 各栏目模板 |
| [compliance-checklist.md](references/compliance-checklist.md) | 内容合规检查 |
| [cover-image-guidelines.md](references/cover-image-guidelines.md) | 封面图设计指南 |
| [article-template.md](references/article-template.md) | 文章完整模板 |
| [review-checklist.md](references/review-checklist.md) | 发布前检查清单 |
| [search-queries.md](references/search-queries.md) | 搜索查询示例 |
| [output-format.md](references/output-format.md) | 信息检索输出格式 |
| [paper-screenshot-guide.md](references/paper-screenshot-guide.md) | 论文截图指南 |
