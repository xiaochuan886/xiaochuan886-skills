---
name: wechat-safe-science-images
description: >
  Add high-quality science/medical/pop-science images to an article with near-zero infringement risk.
  Use this skill whenever the user asks to “配图/找科普图片/加图片让文章更精美/找无版权图片库的图片”,
  especially for WeChat Official Account (公众号) writing workflows (e.g., WeChat Cell Writer / baoyu-post-to-wechat).
  This skill ONLY sources from a strict allowlist (default: Wikimedia Commons) and filters by license
  (allow: Public Domain/CC0/CC BY/CC BY-SA; deny: NC/ND/All rights reserved/unknown).
  Outputs: a local imgs/ folder + image-manifest (internal audit trail) + per-image short captions (NO URLs) to place directly under each image.
---

# WeChat Safe Science Images（科普配图 · 合规优先）

目标：给科普文章补充 **“引用图”**（非自制图），让文章更精美，同时把侵权风险压到最低。

> 定位：这是 WeChat Cell Writer 的配套 skill。
> - Cell Writer 已有“自制图”流程 → 本 skill 负责 **补充引用图**（显微图、机制示意图等）。
> - 不改写文章、不做发布；只负责：找图、验授权、落地文件、生成可审计清单，并给出插入建议。

## 核心原则（必须遵守）

### 1) 严格白名单图源（默认只启用 Commons）
- 默认唯一来源：**Wikimedia Commons**
- 任何非白名单来源：直接拒绝（除非用户明确允许并扩展白名单）

### 2) 严格许可闸门（不通过就不下载/不输出）
允许：
- Public Domain（公有领域）
- CC0
- CC BY
- CC BY-SA

拒绝：
- 任何 **NC（非商用）**
- 任何 **ND（禁止演绎）**
- All rights reserved / Copyrighted
- 授权不明 / 元数据缺失

### 3) 每张图必须可审计（输出 manifest）
对每张输出图片，必须记录：
- file_page_url（文件页）
- original_url（原图直链）
- author / credit / attribution（如有）
- license_short_name（PD/CC0/CC BY/CC BY-SA）
- license_url
- retrieved_at

### 4) 内容匹配优先
先从文章提炼“配图需求清单”，再逐条找图：
- 图的目的（解释机制/对比/总结/真实感）
- 图类型（示意图/机制图/显微图/流程图）
- 关键词（中英）

不要为了“好看”硬塞与内容不匹配的图。

---

## 标准工作流（建议给 Cell Writer 调用）

1. 输入：
   - 文章（markdown/纯文本）或文章大纲
   - 平台：默认公众号
   - 配图数量范围（默认 2~4 张）

2. 输出（对读者“可见”的只保留最小披露）：
   - `imgs/`：下载的图片（统一命名）
   - `image-manifest.json`：每张图的来源与许可（**内部留档**，可包含 URL）
   - `image-captions.md`：每张图对应一行“图源/许可”简注（**不含 URL**），用于直接放在图片下方
   - `image-insert.md`：建议插入位置 + 图注/alt 文本（不含 URL）

3. 审核（强制）：
   - manifest 中每张图 license 必须在 allowlist
   - 发现 NC/ND/unknown → 直接移除并重新选图

---

## CLI 脚本（确定性执行）

使用脚本：`scripts/commons_fetch.mjs`

### 用法

```bash
node scripts/commons_fetch.mjs \
  --query "natural killer cell" \
  --out ./imgs \
  --limit 6
```

可选参数：
- `--query`：检索关键词（建议英文）
- `--out`：输出目录（通常是文章目录下的 `imgs/`）
- `--limit`：候选数量（默认 6，会过滤后可能少于 limit）
- `--min-width`：最小宽度（默认 800）

脚本输出：
- 下载的图片文件
- 同目录 `image-manifest.json`

---

## 写作注意（与公众号工作流一致）

- 文章正文里不要写“我参考了某公众号/某文章”，避免“抄”的观感。
- 参考链接、资料 URL 需在发布/预览前清理；如果要保留证据链，放到 **manifest/内部备注**，不要放正文。

---

## 常见配图类型建议（科普文章）

- 显微图/真实图：用于“真实感/权威感”
- 机制示意图：用于解释“怎么杀伤/怎么识别/怎么协同”
- 对比图（NK vs T）：用于快速建立概念
- 三点总结卡片：用于“读者带走什么”

如果文章主题是 NK 细胞：优先找
- NK cell micrograph
- NK cell cytotoxicity diagram
- ADCC NK cell diagram

