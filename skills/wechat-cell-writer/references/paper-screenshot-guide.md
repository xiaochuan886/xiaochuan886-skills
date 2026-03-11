# 论文截图指南

当文章引用学术论文时，**必须**生成论文截图以增强可信度。

## 触发条件

文章中引用了学术论文（有 DOI 或 PMID）时触发。执行时：
- 默认截取 **1-2 篇核心论文**
- **优先**截取 Nature、Cell、Science、Lancet、NEJM、JAMA 等顶级期刊
- 如果没有顶刊，再选择最关键、最能支撑正文论点的论文

## 推荐截图来源

| 来源 | URL 格式 | 优点 | 成功率 |
|------|----------|------|--------|
| **PubMed** ⭐ | `pubmed.ncbi.nlm.nih.gov/{PMID}/` | 完全公开，格式统一 | 99% |
| **Nature 系列** | `nature.com/articles/{DOI}` | 品牌识别度高 | 95% |
| **Frontiers** | `frontiersin.org/articles/{DOI}/full` | 完全开放获取 | 98% |
| **DOI 跳转** | `doi.org/{DOI}` | 自动跳转到出版商页面 | 90% |

## 使用专用截图脚本

```bash
# 基本用法
npx -y bun ~/.agents/skills/wechat-cell-writer/scripts/screenshot-paper.ts \
  "https://pubmed.ncbi.nlm.nih.gov/38483844/" \
  "$ARTICLE_DIR/imgs/paper-1.png"

# 截取完整页面
npx -y bun ~/.agents/skills/wechat-cell-writer/scripts/screenshot-paper.ts \
  "https://pubmed.ncbi.nlm.nih.gov/38483844/" \
  "$ARTICLE_DIR/imgs/paper-1.png" \
  --full-page

# 自定义视口大小
npx -y bun ~/.agents/skills/wechat-cell-writer/scripts/screenshot-paper.ts \
  "https://doi.org/10.1038/s43587-023-00560-5" \
  "$ARTICLE_DIR/imgs/paper-1.png" \
  --width=1400 --height=900
```

## 文章中插入格式

```markdown
根据《Nature Aging》2024年发表的研究，CAR-T细胞可清除衰老细胞...

![研究来源：Nature Aging](./imgs/paper-1.png)
*图：研究原文摘要（来源：Nature Aging）*
```

## 不推荐的来源

| 来源 | 问题 | 替代方案 |
|------|------|----------|
| **Google Scholar** | 自动查询检测，拒绝访问 | 用 PubMed 或出版商原站 |
| **bioRxiv/medRxiv** | Cloudflare 安全验证拦截 | 等正式发表后用 PubMed |
| **Science Direct** | 付费墙 + 反爬虫 | 用 PubMed 或开放获取版本 |

## 注意事项

- ⚠️ **版权**：仅截图摘要等公开内容，不要截图全文
- ⚠️ **质量**：确保截图清晰，文字可读
- ⚠️ **数量**：每篇文章默认 1-2 张论文截图，避免冗余
- ⚠️ **相关性**：只截图核心引用的论文，不是所有引用都要截图

## 脚本特性

`screenshot-paper.ts` 脚本会自动：
1. 处理 cookies 弹窗（自动接受）
2. 隐藏广告和干扰元素
3. 等待页面加载完成
4. 截图指定区域或完整页面
