# 配图生成指南

本文档详细说明如何为微信公众号文章生成配图。

## ⚠️ 重要规则

1. **核心文字中文**：面向读者的核心标题、标签、说明文字必须使用**简体中文**
2. **减少文字**：AI 生成文字能力有限，尽量用图标、箭头代替文字标签
3. **模型固定**：必须使用 `gemini-3.1-flash-image-preview`，不要使用 imagen 模型
4. **封面默认带标题**：本 skill 的公众号封面默认包含中文标题文字
5. **英文限制**：专业术语、英文名词和字母缩写如 `CAR-T`、`NK`、`TIL`、`iPSC` 可保留，但所有核心说明文字、标签、标题必须为简体中文

---

## 图片规划

| 图片 | 位置 | 用途 | 必须 |
|------|------|------|------|
| **封面图** | 文章顶部 | 吸引点击，展示主题 | ✅ 必需 |
| **配图1** | 文章中部 | 核心概念可视化 | ✅ 必需 |
| **配图2** | 文章后部 | 数据/流程/对比展示 | ✅ 必需 |
| **论文截图** | 引用处 | 展示核心原始文献（1-2篇） | ⚠️ 引用论文时必需 |

> 封面图和正文配图使用 `baoyu-image-gen` 生成；论文截图使用内置脚本。

在开始生成图片前，先检查 `images-plan.md` 中的以下字段：
- `language: zh-CN`
- `text_policy: 核心内容和面向读者的说明文字必须使用简体中文`
- `english_allowed: abbreviations-only`
- `abbreviation_policy: 专业术语和英文缩写可保留，但核心说明文字必须中文`

---

## 封面图设计

### 5 维度设计框架

参考 `baoyu-cover-image` 的设计逻辑：

| 维度 | 选项 | 默认值 | 说明 |
|------|------|--------|------|
| **Type** | conceptual, metaphor, scene, minimal | conceptual | 视觉类型 |
| **Palette** | warm, elegant, cool, dark, earth, vivid, pastel, mono | elegant | 配色方案 |
| **Rendering** | flat-vector, hand-drawn, digital | flat-vector | 渲染风格 |
| **Text** | none, title-only | title-only | 是否包含文字（本 skill 默认带标题） |
| **Mood** | subtle, balanced, bold | balanced | 视觉冲击力 |

### Prompt 模板

```
[Type] style illustration for [主题].
[Rendering] rendering, [Palette] color palette, [Mood] mood.
Include concise Chinese title text in the center safe zone.
Core reader-facing title text must be Simplified Chinese.
Domain abbreviations are allowed when medically necessary.
Clean composition, balanced whitespace, no realistic humans.
Simple silhouettes and icons. Professional healthcare/medical aesthetic.
```

### 示例

**NK细胞存储文章**：
```
Conceptual style illustration for NK cell storage and immune health.
Flat-vector rendering, elegant color palette (blue tones), balanced mood.
Include concise Chinese title text in the center safe zone.
Clean composition with balanced whitespace, no realistic humans.
Show NK cells as glowing blue guardians protecting healthy cells.
Professional medical aesthetic suitable for health article cover.
```

**CAR-T 疗法文章**：
```
Metaphor style illustration for CAR-T cell therapy fighting cancer.
Digital rendering, vivid color palette, bold mood.
Clean composition showing T-cells as soldiers attacking tumor cells.
Include concise Chinese title text. No realistic humans. Professional oncology aesthetic.
```

---

## 配图设计

### Type × Style 矩阵

参考 `baoyu-article-illustrator` 的设计逻辑：

**Types（信息类型）**：

| Type | 用途 | 示例 |
|------|------|------|
| `infographic` | 数据、指标、技术说明 | 细胞数量对比、疗效数据 |
| `scene` | 叙事、情感、场景 | 实验室场景、治疗过程 |
| `flowchart` | 流程、步骤、工作流 | 细胞采集→存储→回输流程 |
| `comparison` | 对比、前后、优劣 | 存储前后效果对比 |
| `framework` | 模型、架构、框架 | 免疫系统层级结构 |
| `timeline` | 历史、演进、里程碑 | 细胞治疗发展历程 |

**Styles（视觉风格）**：

| Style | 特点 | 适用场景 |
|-------|------|----------|
| `notion` | 简约线条，黑白灰 | 技术文档、流程图 |
| `warm` | 温暖色调，手绘感 | 健康科普、关怀类 |
| `minimal` | 极简，大量留白 | 高端定位、专业感 |
| `blueprint` | 蓝图风格，技术感 | 科研前沿、技术分析 |
| `editorial` | 编辑风格，专业感 | 深度报道、行业分析 |

### Prompt 模板

```
[Type] style illustration showing [具体内容].
[Style] visual style, clean and professional.
[具体元素描述].
If labels are needed, use Chinese text (中文).
Core reader-facing labels must be Simplified Chinese.
Domain abbreviations and technical terms such as CAR-T, NK, TIL, iPSC are allowed when necessary.
Prefer icons and arrows over text labels.
Suitable for health/science article.
Choose 9:16 for dense content, otherwise 3:4 or 1:1. Do not use 16:9.
```

### 比例选择规则

- `9:16`：步骤多、信息密度高、需要纵向阅读
- `3:4`：结构中等、图文均衡，默认首选
- `1:1`：概念简单、元素少、适合单一核心图
- 不使用 `16:9` 宽屏配图，手机阅读体验差

### 示例

**NK细胞作用机制**：
```
Infographic style showing NK cell mechanism of action.
Notion visual style, clean and professional.
Three panels showing: 1) NK cell recognizing target, 2) Releasing cytotoxic granules, 3) Target cell destruction.
Scientific accuracy, labeled components. 1:1 aspect ratio.
```

**细胞存储流程**：
```
Flowchart style showing cell storage process.
Blueprint visual style, technical and clean.
Four steps: Blood collection → Cell isolation → Cryopreservation → Quality control.
Simple icons, arrows connecting steps. 9:16 aspect ratio.
```

---

## 信息图设计

当配图需要展示复杂数据时，参考 `baoyu-infographic` 的布局：

### 常用布局

| 布局 | 用途 | 示例 |
|------|------|------|
| `linear-progression` | 流程、步骤 | 细胞治疗流程 |
| `binary-comparison` | A vs B 对比 | 治疗方案对比 |
| `hierarchical-layers` | 层级关系 | 免疫系统结构 |
| `bento-grid` | 多主题概览 | 多种细胞类型介绍 |
| `circular-flow` | 循环过程 | 细胞生命周期 |

### Prompt 示例

```
Infographic showing comparison of three immunotherapy approaches.
Hierarchical-layers layout, warm visual style.
Top section: CAR-T, middle: NK cells, bottom: TIL therapy.
Each section shows mechanism, advantages, and applications.
Clean data visualization, 9:16 or 3:4 aspect ratio.
```

---

## 论文截图

当文章引用学术论文时，使用专用脚本截图。默认保留 1-2 篇核心论文截图，优先顶刊：

```bash
npx -y bun ~/.agents/skills/wechat-cell-writer/scripts/screenshot-paper.ts \
  "https://pubmed.ncbi.nlm.nih.gov/26840489/" \
  "$ARTICLE_DIR/imgs/paper-1.png" \
  --pubmed-url="https://pubmed.ncbi.nlm.nih.gov/26840489/"
```

详见 [paper-screenshot-guide.md](paper-screenshot-guide.md)

---

## 生成命令

```bash
# 封面图 (2.35:1 微信封面比例) - 必须使用 gemini-3.1-flash-image-preview
npx -y bun ~/.agents/skills/baoyu-image-gen/scripts/main.ts \
  --provider google \
  --model gemini-3.1-flash-image-preview \
  --prompt "[封面图 prompt]" \
  --image imgs/cover.png \
  --ar 2.35:1 \
  --imageSize 1K

# 配图 (根据内容选择 9:16 / 3:4 / 1:1) - 必须使用 gemini-3.1-flash-image-preview
npx -y bun ~/.agents/skills/baoyu-image-gen/scripts/main.ts \
  --provider google \
  --model gemini-3.1-flash-image-preview \
  --prompt "[配图 prompt]" \
  --image imgs/figure-1.png \
  --ar 3:4 \
  --imageSize 1K
```

> ⚠️ **重要**：必须使用 `gemini-3.1-flash-image-preview` 模型。`imagen-3.0-generate-002` 需要 Vertex AI 且 API 端点不同，会报 404 错误。

---

## 图片插入正文

**重要**：图片必须在 markdown 正文中插入，而非仅在 frontmatter 声明。

```markdown
<!-- ❌ 错误：只有 frontmatter -->
---
images:
  - ./imgs/figure-1.png
---

<!-- ✅ 正确：正文插入图片 -->
![NK细胞攻击癌细胞示意图](./imgs/figure-1.png)
*NK细胞识别并攻击异常细胞*
```
