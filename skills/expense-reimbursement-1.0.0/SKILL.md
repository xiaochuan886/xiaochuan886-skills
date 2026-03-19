---
name: expense-reimbursement
description: 从发票PDF和行程单提取信息，生成企业标准格式的报销明细表（Excel）。当用户提到"报销"、"发票整理"、"费用明细"、"整理发票"时使用此skill。支持打车发票（含行程单）、住宿发票、高铁电子客票，自动按归属公司分组，向用户确认部门和报销人信息。
---

# 发票报销明细表生成器

从发票PDF自动提取信息，生成企业标准格式的报销明细表。

## 工作流程

1. **扫描发票** → 提取归属公司、金额、日期
2. **按公司分组** → 检测到多个公司时自动拆分
3. **向用户确认** → 部门名称、报销人姓名
4. **生成Excel** → 企业标准样式（边框、字体、对齐）
5. **按公司拆分** → 每个公司一个文件夹，只包含该公司的发票

## 核心逻辑

### 提取规则

**高铁电子客票**：
- 金额格式：`￥162.00` 在 "票价:" 上一行
- 正则：`[¥￥](\d+\.\d{2})`
- 购买方：`购买方名称[：:](\S+)`

**打车发票（竖排版）**：
- 格式：`购 名称：xxx 销 名称：yyy` 然后 `买 售` 然后 `方 方`
- 兜底：`名称[：:]\s*([^\s，。\n]+?有限公司)` 取第一个

**住宿发票**：
- 金额：`（小写）\s*[¥￥]\s*(\d+\.?\d*)`
- 公司：找所有 `xxx有限公司`，**第一个是购买方**

**提取失败时**：打印完整发票文本，根据实际格式调整正则。

### 按公司分组

```python
# 建立发票->公司映射
invoice_to_company = {}
for pdf in invoice_files:
    company = extract_company(pdf)
    invoice_to_company[pdf] = company

# 行程单跟随发票
for pdf in itinerary_files:
    base = pdf.replace('_行程单.pdf', '.pdf')
    invoice_to_company[pdf] = invoice_to_company.get(base)
```

### 只复制属于该公司的发票

```python
# ❌ 错误：复制所有PDF
for f in os.listdir(folder):
    shutil.copy(src, dst)

# ✅ 正确：只复制属于该公司的
for pdf, company in invoice_to_company.items():
    if company == target_company:
        shutil.copy(src, dst)
```

## Excel模板样式

| 位置 | 字体 | 字号 | 加粗 | 对齐 | 边框 |
|------|------|------|------|------|------|
| 标题(A1) | 宋体 | 18pt | 是 | 居中 | 无 |
| 表头(行2-3) | 宋体 | 12pt | 否 | 居中 | 无 |
| 列标题(行4) | 宋体 | 12pt | 否 | 居中 | thin |
| 数据行 | 宋体 | 10pt | 否 | 居中 | thin |
| 合计行 | 宋体 | 12pt | 否 | 左对齐 | thin |

完整实现见 `scripts/create_expense_sheet.py`。

## 使用示例

```
用户：帮我整理这个文件夹里的发票
     文件夹：/Downloads/3月苏州+杭州出差

执行：
1. 扫描 → 检测到2个归属公司
2. 确认 → 部门：市场部，报销人：陆俊峰
3. 生成 → 2个子文件夹，每个包含发票+报销明细表
```

## 参考文件

- `references/invoice_patterns.md` - 发票格式详解
- `scripts/create_expense_sheet.py` - Excel生成脚本
