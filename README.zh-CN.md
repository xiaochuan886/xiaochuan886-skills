# xiaochuan886-skills

[English](./README.md) | 简体中文

AI Agent 技能集合，用于微信公众号内容创作和科普传播。

## 可用技能

### 1. wechat-cell-writer

自动生成细胞治疗和生物医学主题的微信公众号文章。

- 检索最新科研论文和行业新闻
- 创作面向普通读者的优质合规文章（1500-3000字）
- 支持三个栏目：科研前沿解读、细胞科普系列、健康管家Tips

**安装：**
```bash
npx skills add xiaochuan886/xiaochuan886-skills --skill wechat-cell-writer
```

### 2. wechat-safe-science-images

为文章添加高质量科普图片，近乎零版权风险。

- 仅从可信白名单获取（默认：Wikimedia Commons）
- 严格许可证过滤（仅限 Public Domain/CC0/CC BY/CC BY-SA）
- 输出本地图片和规范的署名信息

**安装：**
```bash
npx skills add xiaochuan886/xiaochuan886-skills --skill wechat-safe-science-images
```

## 安装全部技能

```bash
npx skills add xiaochuan886/xiaochuan886-skills
```

## 仓库结构

```
xiaochuan886-skills/
├── skills/
│   ├── wechat-cell-writer/
│   │   ├── SKILL.md           # 主技能定义
│   │   ├── references/        # 写作指南和模板
│   │   ├── scripts/           # 工作流自动化脚本
│   │   └── agents/            # Agent UI 元数据
│   └── wechat-safe-science-images/
│       └── SKILL.md
├── README.md
└── LICENSE
```

## 许可证

MIT
