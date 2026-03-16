# xiaochuan886-skills

English | [简体中文](./README.zh-CN.md)

A curated collection of Codex skills for content creation and social growth workflows.

## Focused Skill Set (Product Video + XHS)

### 1. `product-promo-video`
Generate trend-aware product promo videos from product image(s) and copy.

- Builds creative brief + 2-segment storyboard
- Produces keyframes, segment clips, and final concatenated campaign video
- Keeps packaging/text provenance and physical realism constraints

### 2. `xhs-publish-trace`
Trace newly published Xiaohongshu notes back to public links and engagement metrics.

- Searches and verifies notes with `feed_id` + `xsec_token`
- Builds final public note URL
- Returns available metrics (likes, collects, comments, etc.)

### 3. `product-video-xhs-ops`
LLM-led end-to-end ops workflow for product video production, publishing, trace-back, and ledgering.

- Uses `product-promo-video` as the generation engine
- Uses `xhs-publish-trace` for post-publish link recovery and metrics check
- Writes deterministic daily records for operations and reporting

## Workflow Relationship

1. Generate campaign video with `product-promo-video`
2. Publish and reverse-trace the note with `xhs-publish-trace`
3. Run operational closure (validation, archive, ledger) with `product-video-xhs-ops`

## Other Skills

- `wechat-cell-writer`
- `wechat-safe-science-images`

These are maintained in the same `skills/` directory as the XHS workflow skills.

## Install

Install all skills from this repo:

```bash
npx skills add xiaochuan886/xiaochuan886-skills
```

Install a specific skill:

```bash
npx skills add xiaochuan886/xiaochuan886-skills --skill product-promo-video
npx skills add xiaochuan886/xiaochuan886-skills --skill xhs-publish-trace
npx skills add xiaochuan886/xiaochuan886-skills --skill product-video-xhs-ops
```

## Repository Structure

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

## License

MIT
