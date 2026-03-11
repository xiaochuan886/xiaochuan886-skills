# xiaochuan886-skills

English | [简体中文](./README.zh-CN.md)

A collection of AI agent skills for WeChat content creation and science communication.

## Available Skills

### 1. wechat-cell-writer

Automatically generates WeChat Official Account articles about cell therapy and biomedical topics.

- Researches latest scientific papers and industry news
- Creates engaging, compliant articles (1500-3000 words) for general readers
- Supports three columns: Research Frontiers, Cell Science Popularization, and Health Tips

**Install:**
```bash
npx skills add xiaochuan886/xiaochuan886-skills --skill wechat-cell-writer
```

### 2. wechat-safe-science-images

Add high-quality science/medical/pop-science images to articles with near-zero infringement risk.

- Sources only from trusted allowlist (default: Wikimedia Commons)
- Filters by license (Public Domain/CC0/CC BY/CC BY-SA only)
- Outputs local images with proper attribution

**Install:**
```bash
npx skills add xiaochuan886/xiaochuan886-skills --skill wechat-safe-science-images
```

## Install All Skills

```bash
npx skills add xiaochuan886/xiaochuan886-skills
```

## Repository Structure

```
xiaochuan886-skills/
├── skills/
│   ├── wechat-cell-writer/
│   │   ├── SKILL.md           # Main skill definition
│   │   ├── references/        # Writing guides and templates
│   │   ├── scripts/           # Workflow automation scripts
│   │   └── agents/            # Agent UI metadata
│   └── wechat-safe-science-images/
│       └── SKILL.md
├── README.md
└── LICENSE
```

## License

MIT
