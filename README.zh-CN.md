# xiaochuan886-skills

[English](./README.md) | 简体中文

这是一个面向内容创作与社媒增长的 Codex Skills 仓库。

## 当前重点技能（商品视频 + 小红书）

### 1. `product-promo-video`
基于商品图和文案生成趋势化带货短视频。

- 生成创意简报与双分镜（2 段）脚本
- 产出关键帧、分段视频与最终拼接成片
- 内置包装/文字来源约束与物理真实感约束

### 2. `xhs-publish-trace`
对已发布小红书笔记做反查，找回公开链接并读取可用互动数据。

- 通过 `feed_id` + `xsec_token` 校验目标笔记
- 构造最终公开笔记链接
- 返回可获取的互动指标（点赞、收藏、评论等）

### 3. `product-video-xhs-ops`
以 LLM 为核心的端到端运营流程：视频生产、发布、反查、台账落盘。

- 调用 `product-promo-video` 作为生成引擎
- 调用 `xhs-publish-trace` 做发布后链接回溯与数据核验
- 输出结构化日常记录，便于复盘与运营统计

## 三者协作关系

1. 使用 `product-promo-video` 生成商品视频
2. 使用 `xhs-publish-trace` 反查公开笔记链接与互动数据
3. 使用 `product-video-xhs-ops` 完成校验、归档、台账写入

## 其他技能

- `wechat-cell-writer`
- `wechat-safe-science-images`

这两个技能与小红书工作流技能一样，统一维护在 `skills/` 目录下。

## 安装方式

安装仓库全部技能：

```bash
npx skills add xiaochuan886/xiaochuan886-skills
```

安装单个技能：

```bash
npx skills add xiaochuan886/xiaochuan886-skills --skill product-promo-video
npx skills add xiaochuan886/xiaochuan886-skills --skill xhs-publish-trace
npx skills add xiaochuan886/xiaochuan886-skills --skill product-video-xhs-ops
```

## 仓库结构

```text
xiaochuan886-skills/
├── skills/
│   ├── product-promo-video/
│   ├── xhs-publish-trace/
│   ├── product-video-xhs-ops/
│   ├── wechat-cell-writer/
│   └── wechat-safe-science-images/
├── README.md
├── README.zh-CN.md
└── LICENSE
```

## 许可证

MIT
