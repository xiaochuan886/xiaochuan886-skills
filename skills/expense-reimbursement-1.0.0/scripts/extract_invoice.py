#!/usr/bin/env python3
"""
从发票PDF提取关键信息

使用方法：
    python extract_invoice.py 发票.pdf

输出JSON格式：
{
    "file": "发票文件名",
    "company": "归属公司",
    "amount": 金额,
    "date": "日期",
    "project": "类型(打车/住宿/高铁)",
    "traveler": "出行人"
}
"""

import pdfplumber
import re
import json
import sys


def extract_invoice_info(pdf_path):
    """从发票PDF提取关键信息"""
    with pdfplumber.open(pdf_path) as pdf:
        text = "".join(page.extract_text() or "" for page in pdf.pages)

    info = {
        'file': pdf_path,
        'company': None,
        'traveler': None,
        'amount': None,
        'date': None,
        'project': None,
    }

    # 判断发票类型
    is_railway = '铁路电子客票' in text
    is_accommodation = '住宿服务' in text or '住宿费' in text

    if is_railway:
        info['project'] = '高铁'
        
        # 金额（在票价:前面）
        amount_match = re.search(r'[¥￥](\d+\.\d{2})', text)
        if amount_match:
            info['amount'] = float(amount_match.group(1))
            
        # 购买方
        company_match = re.search(r'购买方名称[：:](\S+)', text)
        if company_match:
            info['company'] = company_match.group(1).strip()
            
        # 出行人
        traveler_match = re.search(r'\d{6}\*+\d{4}\s+(\S+)', text)
        if traveler_match:
            info['traveler'] = traveler_match.group(1)
            
        # 出行日期
        date_match = re.search(r'(\d{4})年(\d{2})月(\d{2})日\s+\d{2}:\d{2}开', text)
        if date_match:
            info['date'] = f"{date_match.group(1)}-{date_match.group(2)}-{date_match.group(3)}"
            
    elif is_accommodation:
        info['project'] = '住宿'
        
        # 金额
        amount_match = re.search(r'（小写）\s*[¥￥]\s*(\d+\.?\d*)', text)
        if amount_match:
            info['amount'] = float(amount_match.group(1))
        
        # 公司（第一个有限公司是购买方）
        companies = re.findall(r'([^，。\s\n]+?有限公司)', text)
        if companies:
            info['company'] = companies[0]
        
        # 日期
        date_match = re.search(r'(\d{4})年(\d{1,2})月(\d{1,2})日', text)
        if date_match:
            info['date'] = f"{date_match.group(1)}-{date_match.group(2).zfill(2)}-{date_match.group(3).zfill(2)}"
            
    else:
        info['project'] = '打车'
        
        # 金额
        amount_match = re.search(r'（小写）[¥￥]?\s*(\d+\.?\d*)', text)
        if amount_match:
            info['amount'] = float(amount_match.group(1))
        
        # 公司（多种模式）
        company_patterns = [
            r'购买方名称[：:]\s*([^\s，。\n]+)',
            r'买\s*方?\s*名称[：:]\s*([^\s，。\n]+)',
        ]
        for p in company_patterns:
            m = re.search(p, text)
            if m:
                info['company'] = m.group(1).strip()
                break
        
        # 兜底：找第一个"名称:xxx有限公司"
        if not info['company']:
            all_companies = re.findall(r'名称[：:]\s*([^\s，。\n]+?有限公司)', text)
            if all_companies:
                info['company'] = all_companies[0]
            
        # 日期
        date_match = re.search(r'(\d{4})年(\d{1,2})月(\d{1,2})日', text)
        if date_match:
            info['date'] = f"{date_match.group(1)}-{date_match.group(2).zfill(2)}-{date_match.group(3).zfill(2)}"

    return info


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("用法: python extract_invoice.py 发票.pdf")
        sys.exit(1)
    
    info = extract_invoice_info(sys.argv[1])
    print(json.dumps(info, ensure_ascii=False, indent=2))
