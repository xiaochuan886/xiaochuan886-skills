# 配图生成指南

用于 OPC 社群内容的公众号配图和小红书图组。

## 基本规则

- 面向读者的核心文字必须是简体中文
- 能少写字就少写字，优先用结构、图标和层次表达
- 风格以商业、信息、创业感为主，不要医疗或科研审美
- 封面图可以带标题；正文图尽量少字

## 建议图片

| 图片 | 用途 | 比例 | 必需 |
|------|------|------|------|
| 封面图 | 公众号点击入口 | 2.35:1 | 是 |
| 配图1 | 框架/路径 | 3:4 | 是 |
| 配图2 | 对比/时间线/流程 | 9:16 或 3:4 | 是 |
| XHS 图组/首图 | 小红书派生稿视觉 | 3:4 或 1:1 | 否 |

## 推荐风格

- `framework`：判断框架、能力模型、路径图
- `comparison`：个体户 vs 一人有限公司、不同路径对比
- `timeline`：政策或案例时间线
- `editorial`：深度内容封面
- `minimal`：结构清晰、字少、专业

## Skill 路由

- 公众号封面：`baoyu-cover-image`
- 正文配图：`baoyu-article-illustrator`，信息图可选 `baoyu-infographic`
- 小红书图片：`baoyu-xhs-images`

## 默认模型

- Gemini 生图默认模型统一为：`gemini-3.1-flash-image-preview`
- `images-plan.md` 中应在全局写 `default_image_model`，并在每个图片块写 `default_model`

小红书图片不要再走通用封面 skill，优先用 `baoyu-xhs-images` 产出更贴近平台习惯的图组。对 OPC 主题，优先考虑这些 preset：

- `knowledge-card`
- `checklist`
- `pro-summary`
- `versus`

## Prompt 要点

```text
[image type] for OPC / one-person company topic.
Professional editorial or business infographic style.
Simplified Chinese for any reader-facing text.
No medical or laboratory imagery.
Clean layout, strong hierarchy, mobile-friendly.
```
