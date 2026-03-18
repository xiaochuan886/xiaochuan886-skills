import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import process from "node:process";

import {
  COLOR_PRESETS,
  FONT_FAMILY_MAP,
  FONT_SIZE_OPTIONS,
  THEME_NAMES,
  extractSummaryFromBody,
  extractTitleFromMarkdown,
  formatTimestamp,
  parseArgs,
  parseFrontmatter,
  renderMarkdownDocument,
  replaceMarkdownImagesWithPlaceholders,
  resolveContentImages,
  serializeFrontmatter,
  stripWrappingQuotes,
} from "baoyu-md";

interface ImageInfo {
  placeholder: string;
  localPath: string;
  originalPath: string;
}

interface ParsedResult {
  title: string;
  author: string;
  summary: string;
  htmlPath: string;
  backupPath?: string;
  contentImages: ImageInfo[];
}

export async function convertMarkdown(
  markdownPath: string,
  options?: {
    title?: string;
    theme?: string;
    keepTitle?: boolean;
    citeStatus?: boolean;
    primaryColor?: string;
    fontFamily?: string;
    fontSize?: string;
    codeTheme?: string;
    isMacCodeBlock?: boolean;
    isShowLineNumber?: boolean;
    countStatus?: boolean;
    legend?: string;
  },
): Promise<ParsedResult> {
  const baseDir = path.dirname(markdownPath);
  const content = fs.readFileSync(markdownPath, "utf-8");
  const theme = options?.theme;
  const keepTitle = options?.keepTitle ?? false;
  const citeStatus = options?.citeStatus ?? false;

  const { frontmatter, body } = parseFrontmatter(content);

  let title = stripWrappingQuotes(options?.title ?? "")
    || stripWrappingQuotes(frontmatter.title ?? "")
    || extractTitleFromMarkdown(body);
  if (!title) {
    title = path.basename(markdownPath, path.extname(markdownPath));
  }

  const author = stripWrappingQuotes(frontmatter.author ?? "");
  let summary = stripWrappingQuotes(frontmatter.description ?? "")
    || stripWrappingQuotes(frontmatter.summary ?? "");
  if (!summary) {
    summary = extractSummaryFromBody(body, 120);
  }

  const { images, markdown: rewrittenBody } = replaceMarkdownImagesWithPlaceholders(
    body,
    "MDTOHTMLIMGPH_",
  );
  const rewrittenMarkdown = `${serializeFrontmatter(frontmatter)}${rewrittenBody}`;

  console.error(
    `[opc-markdown-to-html] Rendering with theme: ${theme ?? "opc-briefing"}, keepTitle: ${keepTitle}, citeStatus: ${citeStatus}`,
  );

  const { html } = await renderMarkdownDocument(rewrittenMarkdown, {
    codeTheme: options?.codeTheme,
    citeStatus,
    countStatus: options?.countStatus,
    defaultTitle: title,
    fontFamily: options?.fontFamily,
    fontSize: options?.fontSize,
    isMacCodeBlock: options?.isMacCodeBlock,
    isShowLineNumber: options?.isShowLineNumber,
    keepTitle,
    legend: options?.legend,
    primaryColor: options?.primaryColor,
    theme,
  });

  const finalHtmlPath = markdownPath.replace(/\.md$/i, ".html");
  let backupPath: string | undefined;

  if (fs.existsSync(finalHtmlPath)) {
    backupPath = `${finalHtmlPath}.bak-${formatTimestamp()}`;
    console.error(`[opc-markdown-to-html] Backing up existing file to: ${backupPath}`);
    fs.renameSync(finalHtmlPath, backupPath);
  }

  fs.writeFileSync(finalHtmlPath, html, "utf-8");

  const hasRemoteImages = images.some((image) =>
    image.originalPath.startsWith("http://") || image.originalPath.startsWith("https://"),
  );
  const tempDir = hasRemoteImages
    ? fs.mkdtempSync(path.join(os.tmpdir(), "opc-markdown-to-html-"))
    : baseDir;
  const contentImages = await resolveContentImages(images, baseDir, tempDir, "opc-markdown-to-html");

  let finalContent = fs.readFileSync(finalHtmlPath, "utf-8");
  for (const image of contentImages) {
    const imgTag = `<img src="${image.originalPath}" data-local-path="${image.localPath}" style="display: block; width: 100%; margin: 1.5em auto;">`;
    finalContent = finalContent.replace(image.placeholder, imgTag);
  }
  fs.writeFileSync(finalHtmlPath, finalContent, "utf-8");

  console.error(`[opc-markdown-to-html] HTML saved to: ${finalHtmlPath}`);

  return {
    title,
    author,
    summary,
    htmlPath: finalHtmlPath,
    backupPath,
    contentImages,
  };
}

function printUsage(exitCode = 0): never {
  console.log(`Convert Markdown to HTML with OPC themes

Usage:
  npx -y bun main.ts <markdown_file> [options]

Options:
  --title <title>     Override title
  --theme <name>      Theme name (${THEME_NAMES.join(", ")}). Default: opc-briefing
  --color <name|hex>  Primary color (${Object.keys(COLOR_PRESETS).join(", ")})
  --font-family <v>   Font family (${Object.keys(FONT_FAMILY_MAP).join(", ")})
  --font-size <N>     Font size (${FONT_SIZE_OPTIONS.join(", ")})
  --cite              Convert ordinary external links to bottom citations. Default: off
  --keep-title        Keep the first heading in content. Default: false (removed)
  --help              Show this help

Output:
  HTML file saved to same directory as input markdown file.
  Example: article.md -> article.html

  If HTML file already exists, it will be backed up first:
  article.html -> article.html.bak-YYYYMMDDHHMMSS

Output JSON format:
{
  "title": "Article Title",
  "htmlPath": "/path/to/article.html",
  "backupPath": "/path/to/article.html.bak-20260128180000",
  "contentImages": [...]
}

Example:
  npx -y bun main.ts article.md
  npx -y bun main.ts article.md --theme opc-briefing
  npx -y bun main.ts article.md --theme opc-editorial
  npx -y bun main.ts article.md --cite
`);
  process.exit(exitCode);
}

async function main(): Promise<void> {
  const args = process.argv.slice(2);
  if (args.length === 0 || args.includes("--help") || args.includes("-h")) {
    printUsage(0);
  }

  let title: string | undefined;
  const titleIndex = args.indexOf("--title");
  if (titleIndex >= 0 && args[titleIndex + 1]) {
    title = args[titleIndex + 1];
  }
  const titleInline = args.find((arg) => arg.startsWith("--title="));
  if (!title && titleInline) {
    title = titleInline.slice("--title=".length);
  }

  const parsed = parseArgs(args);
  if (!parsed) {
    printUsage(1);
  }

  if (!parsed.inputPath) {
    console.error("Error: Markdown file path is required");
    process.exit(1);
  }

  if (!fs.existsSync(parsed.inputPath)) {
    console.error(`Error: File not found: ${parsed.inputPath}`);
    process.exit(1);
  }

  const result = await convertMarkdown(parsed.inputPath, {
    citeStatus: parsed.citeStatus,
    codeTheme: parsed.codeTheme,
    countStatus: parsed.countStatus,
    fontFamily: parsed.fontFamily,
    fontSize: parsed.fontSize,
    isMacCodeBlock: parsed.isMacCodeBlock,
    isShowLineNumber: parsed.isShowLineNumber,
    keepTitle: parsed.keepTitle,
    legend: parsed.legend,
    primaryColor: parsed.primaryColor,
    theme: parsed.theme || "opc-briefing",
    title,
  });
  console.log(JSON.stringify(result, null, 2));
}

await main().catch((error) => {
  console.error(`Error: ${error instanceof Error ? error.message : String(error)}`);
  process.exit(1);
});
