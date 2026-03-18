# 发布指南

## 公众号发布

默认只处理公众号发布。小红书 v1 只输出内容稿，不包含发布动作。

## 主力模板

- `opc-briefing`
- `opc-editorial`
- `opc-default`

## 备选模板

- `opc-chapters`
- `opc-feature`
- `opc-report`

## 主题建议

| 内容类型 | 主题 | 颜色 |
|----------|------|------|
| 政策解读 | `opc-briefing` | `black` |
| 创业指南 | `opc-briefing` | `blue` |
| 案例拆解 | `opc-editorial` | `rose` |

## HTML 排版

以下命令默认假设 `opc-markdown-to-html` 已安装到 `~/.agents/skills/`。
如果直接使用源码仓库，请把路径替换为本地仓库中的 `skills/opc-markdown-to-html/scripts/main.ts`。

```bash
npx -y bun ~/.agents/skills/opc-markdown-to-html/scripts/main.ts \
  article.publish.md \
  --theme opc-briefing \
  --color black \
  --cite
```

## 发布命令

```bash
npx -y bun ~/.agents/skills/baoyu-post-to-wechat/scripts/wechat-api.ts \
  article.publish.html \
  --cover imgs/cover.png \
  --author "OPC成员社群"
```

## 发布前检查

- 删除 URL
- 确认参考资料为纯文本
- 确认已经用 `opc-markdown-to-html` 转为 HTML
- 默认优先使用 `opc-briefing`，案例类再切到 `opc-editorial`
- 检查封面和正文图片是否存在
- 再次检查 CTA 是否为软转化
