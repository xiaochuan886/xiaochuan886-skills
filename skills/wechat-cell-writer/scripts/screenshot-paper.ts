#!/usr/bin/env bun
/**
 * 论文截图脚本 - 自动处理 cookies 弹窗并截图
 * 用法: bun screenshot-paper.ts <url> <output_path>
 */

import { chromium, Browser, Page } from 'playwright';
import { existsSync, mkdirSync } from 'fs';
import { dirname } from 'path';

// 常见的广告/促销元素选择器（需要隐藏）
const AD_SELECTORS = [
  // 通用顶部横幅
  '.top-banner',
  '.banner-top',
  '.promo-banner',
  '.marketing-banner',
  '.announcement-banner',
  '.site-notice',
  '.header-banner',
  '.notification-bar',
  '.alert-bar',
  '.campaign-banner',

  // Nature/Springer
  '.nature-banner',
  '.springer-banner',
  '.c-nature-banner',
  '[data-test="promo-banner"]',
  '.c-promo-banner',
  '.marketing-section',

  // 订阅/注册提示
  '.subscribe-banner',
  '.registration-banner',
  '.signup-prompt',
  '.newsletter-signup',
  '.email-signup',

  // 通用广告容器
  '[class*="ad-"]',
  '[class*="ads-"]',
  '[class*="advert"]',
  '[id*="ad-"]',
  '[id*="ads-"]',
  '.advertisement',

  // 弹窗/浮层
  '.popup-overlay',
  '.modal-overlay:not(.cookie-modal)',
  '.lightbox',
];

// 隐藏广告元素的 CSS
const HIDE_ADS_CSS = `
  /* 顶部广告条 */
  .top-banner, .banner-top, .promo-banner, .marketing-banner,
  .announcement-banner, .site-notice, .header-banner,
  .notification-bar, .alert-bar, .campaign-banner,

  /* Nature/Springer */
  .nature-banner, .springer-banner, .c-nature-banner,
  [data-test="promo-banner"], .c-promo-banner, .marketing-section,

  /* 订阅提示 */
  .subscribe-banner, .registration-banner, .signup-prompt,
  .newsletter-signup, .email-signup,

  /* 通用广告 */
  [class*="ad-"], [class*="ads-"], [class*="advert"],
  [id*="ad-"], [id*="ads-"], .advertisement,

  /* 弹窗 */
  .popup-overlay, .lightbox {
    display: none !important;
    visibility: hidden !important;
    height: 0 !important;
    overflow: hidden !important;
  }
`;

async function hideAds(page: Page): Promise<void> {
  // 注入 CSS 隐藏广告
  await page.addStyleTag({ content: HIDE_ADS_CSS });

  // 额外移除一些顽固的广告元素
  await page.evaluate(() => {
    const selectors = [
      '.top-banner', '.banner-top', '.promo-banner',
      '[data-test="promo-banner"]', '.c-promo-banner',
      '.marketing-banner', '.announcement-banner',
      '[class*="ad-container"]', '[id*="ad-container"]',
    ];

    selectors.forEach(sel => {
      document.querySelectorAll(sel).forEach(el => {
        (el as HTMLElement).style.display = 'none';
        (el as HTMLElement).style.height = '0';
      });
    });
  });

  console.log('🚫 Ads hidden');
}

const PUBMED_CLEAN_CSS = `
  .usa-banner,
  .ncbi-header,
  .search-form,
  .search-panel,
  .search-actions,
  .page-actions-bar,
  .journal-actions,
  .article-sidebar,
  .shortcuts,
  .social-share-bar,
  aside,
  [class*="sidebar"],
  [class*="side-panel"] {
    display: none !important;
    visibility: hidden !important;
  }

  .article-page,
  .article-page .main-content,
  main {
    max-width: 980px !important;
    width: 980px !important;
    margin: 0 auto !important;
  }

  body {
    background: #ffffff !important;
  }
`;

function isPubMedUrl(url: string): boolean {
  try {
    const parsed = new URL(url);
    return parsed.hostname.includes('pubmed.ncbi.nlm.nih.gov');
  } catch {
    return false;
  }
}

async function optimizePubMedLayout(page: Page): Promise<void> {
  await page.addStyleTag({ content: PUBMED_CLEAN_CSS });
  await page.evaluate(() => {
    const removeSelectors = [
      '.usa-banner',
      '.ncbi-header',
      '.search-form',
      '.search-panel',
      '.page-actions-bar',
      '.article-sidebar',
      '.shortcuts',
      '.social-share-bar',
      'aside',
    ];

    removeSelectors.forEach(sel => {
      document.querySelectorAll(sel).forEach(el => {
        (el as HTMLElement).style.display = 'none';
      });
    });

    const anchor = document.querySelector('h1.heading-title, .heading-title, .article-title');
    if (anchor) {
      anchor.scrollIntoView({ block: 'start' });
      window.scrollBy(0, -24);
    }
  });
  await page.waitForTimeout(300);
  console.log('🧹 PubMed layout optimized');
}

// 常见的 cookies 接受按钮选择器
const COOKIE_SELECTORS = [
  // 通用选择器
  'button:has-text("Accept")',
  'button:has-text("Accept All")',
  'button:has-text("Accept all")',
  'button:has-text("accept all")',
  'button:has-text("I Accept")',
  'button:has-text("Agree")',
  'button:has-text("Agree to all")',
  'button:has-text("OK")',
  'button:has-text("Allow all")',
  'button:has-text("Allow")',
  'button:has-text("同意")',
  'button:has-text("接受")',
  'button:has-text("确认")',

  // Nature/Springer Nature
  'button[data-test="accept-all-cookies"]',
  '#onetrust-accept-btn-handler',
  '.onetrust-accept-btn-handler',

  // Science/AAAS
  'button[class*="cookie"]',
  'button[class*="consent"]',

  // Cell/Elsevier
  'button#accept-btn',
  '.cc-accept',
  '#ccc-notify-accept',

  // Generic GDPR
  '[class*="cookie-consent"] button',
  '[class*="cookiebanner"] button',
  '[id*="cookie"] button:has-text("Accept")',
  '[data-testid*="cookie"] button',
  '#gdpr-consent-accept',

  // OneTrust
  '#onetrust-button-group button:first-child',
  '.ot-pc-accept-all-handler',

  // Quantcast
  '.qc-cmp2-summary-buttons button:first-child',

  // Cookiebot
  '#CybotCookiebotDialogBodyLevelButtonLevelOptinAllowAll',
];

async function acceptCookies(page: Page): Promise<boolean> {
  // 等待页面加载
  await page.waitForLoadState('networkidle').catch(() => {});

  // 尝试每个选择器
  for (const selector of COOKIE_SELECTORS) {
    try {
      const button = page.locator(selector).first();
      if (await button.isVisible({ timeout: 1000 })) {
        console.log(`Found cookie button: ${selector}`);
        await button.click();
        // 等待弹窗消失
        await page.waitForTimeout(1000);
        console.log('✅ Cookies accepted');
        return true;
      }
    } catch (e) {
      // 继续尝试下一个选择器
    }
  }

  console.log('ℹ️ No cookie popup found or already accepted');
  return false;
}

const SECURITY_KEYWORDS = [
  'cloudflare',
  'verify you are human',
  'checking your browser',
  'checking if the site connection is secure',
  'attention required',
  'security check',
  'captcha',
  'enable javascript and cookies',
  'please stand by',
  'please verify you are human',
  '安全验证',
  '人机验证',
  '请完成验证',
  '访问受限',
  '验证您是真人',
];

const OVERLAY_SELECTORS = [
  '#challenge-stage',
  '#cf-challenge-running',
  '#cf-wrapper',
  '.cf-browser-verification',
  '.cf-challenge-container',
  '[class*="captcha"]',
  '[id*="captcha"]',
  '[class*="challenge"]',
  '[id*="challenge"]',
  '[class*="cookie"]',
  '[id*="cookie"]',
];

type PageCheck = {
  ok: boolean;
  reasons: string[];
};

async function analyzePage(page: Page): Promise<PageCheck> {
  const title = (await page.title().catch(() => '')).toLowerCase();
  const bodyText = (await page.locator('body').innerText().catch(() => '')).toLowerCase();
  const textWindow = bodyText.slice(0, 5000);
  const reasons: string[] = [];

  for (const keyword of SECURITY_KEYWORDS) {
    if (title.includes(keyword) || textWindow.includes(keyword)) {
      reasons.push(`matched keyword: ${keyword}`);
    }
  }

  for (const selector of OVERLAY_SELECTORS) {
    try {
      const locator = page.locator(selector).first();
      if (await locator.isVisible({ timeout: 300 })) {
        reasons.push(`visible overlay: ${selector}`);
      }
    } catch {
      // ignore individual selector failures
    }
  }

  const headingExists = await page.locator('h1, .heading-title, .article-title').first().isVisible({ timeout: 500 }).catch(() => false);
  if (!headingExists) {
    reasons.push('no visible article heading found');
  }

  return {
    ok: reasons.length === 0,
    reasons,
  };
}

async function screenshot(url: string, outputPath: string, options: {
  fullPage?: boolean;
  viewport?: { width: number; height: number };
  timeout?: number;
  pubmedUrl?: string;
} = {}): Promise<void> {
  const {
    fullPage = false,
    viewport = { width: 1280, height: 900 },
    timeout = 30000,
    pubmedUrl,
  } = options;

  // 确保输出目录存在
  const outputDir = dirname(outputPath);
  if (!existsSync(outputDir)) {
    mkdirSync(outputDir, { recursive: true });
  }

  let browser: Browser | null = null;

  try {
    console.log(`🌐 Opening: ${url}`);
    browser = await chromium.launch({ headless: true });
    const context = await browser.newContext({
      viewport,
      userAgent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    });
    const page = await context.newPage();

    // 设置超时
    page.setDefaultTimeout(timeout);

    // 访问页面
    await page.goto(url, { waitUntil: 'domcontentloaded', timeout });

    // 处理 cookies 弹窗
    await acceptCookies(page);

    // 隐藏广告元素
    await hideAds(page);

    // PubMed 专项优化：隐藏顶部和右侧干扰信息
    if (isPubMedUrl(url)) {
      await optimizePubMedLayout(page);
    }

    // 等待主要内容加载
    await page.waitForLoadState('networkidle').catch(() => {});
    await page.waitForTimeout(500);

    let pageCheck = await analyzePage(page);
    if (!pageCheck.ok) {
      console.warn(`⚠️ Suspicious page detected for ${url}`);
      pageCheck.reasons.forEach(reason => console.warn(`  - ${reason}`));

      if (pubmedUrl && !isPubMedUrl(url)) {
        console.log(`↪ Falling back to PubMed: ${pubmedUrl}`);
        await page.goto(pubmedUrl, { waitUntil: 'domcontentloaded', timeout });
        await acceptCookies(page);
        await hideAds(page);
        if (isPubMedUrl(pubmedUrl)) {
          await optimizePubMedLayout(page);
        }
        await page.waitForLoadState('networkidle').catch(() => {});
        await page.waitForTimeout(500);
        pageCheck = await analyzePage(page);
      }
    }

    if (!pageCheck.ok) {
      console.warn('⚠️ Screenshot page is still suspicious after fallback attempt.');
      pageCheck.reasons.forEach(reason => console.warn(`  - ${reason}`));
    }

    // 截图
    console.log(`📸 Taking screenshot...`);
    await page.screenshot({
      path: outputPath,
      fullPage,
    });

    console.log(`✅ Screenshot saved: ${outputPath}`);

  } catch (error) {
    console.error('❌ Error:', error);
    throw error;
  } finally {
    if (browser) {
      await browser.close();
    }
  }
}

// 命令行入口
const args = process.argv.slice(2);

if (args.length < 2) {
  console.log(`
📄 论文截图工具 - 自动处理 cookies 弹窗

用法:
  bun screenshot-paper.ts <url> <output_path> [options]

参数:
  url          论文页面 URL
  output_path  截图保存路径

选项:
  --full-page  截取完整页面（默认只截视口大小）
  --width=N    视口宽度（默认 1280）
  --height=N   视口高度（默认 900）
  --pubmed-url=URL  如检测到 Cloudflare/验证/遮挡问题，自动回退到 PubMed 页面

示例:
  # 截取 Nature 文章
  bun screenshot-paper.ts "https://nature.com/articles/xxx" "./imgs/paper-1.png"

  # 截取完整页面
  bun screenshot-paper.ts "https://pubmed.ncbi.nlm.nih.gov/12345/" "./imgs/paper-1.png" --full-page
`);
  process.exit(1);
}

const url = args[0];
const outputPath = args[1];

// 解析选项
const options: Parameters<typeof screenshot>[2] = {
  fullPage: args.includes('--full-page'),
};

const widthArg = args.find(a => a.startsWith('--width='));
const heightArg = args.find(a => a.startsWith('--height='));
const pubmedUrlArg = args.find(a => a.startsWith('--pubmed-url='));

if (widthArg || heightArg) {
  options.viewport = {
    width: widthArg ? parseInt(widthArg.split('=')[1]) : 1280,
    height: heightArg ? parseInt(heightArg.split('=')[1]) : 900,
  };
}

if (pubmedUrlArg) {
  options.pubmedUrl = pubmedUrlArg.split('=')[1];
}

screenshot(url, outputPath, options).catch(() => process.exit(1));
