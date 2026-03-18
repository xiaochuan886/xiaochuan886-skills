---
name: opc-markdown-to-html
description: Converts Markdown to styled HTML with independently maintained OPC and WeChat-friendly themes. Use when the user asks for "markdown to html", "公众号排版", "微信排版", "md转html", "文章套模板", "套我们自己的模板", or wants HTML output using the team's own typography and layout styles.
version: 0.1.0
metadata:
  openclaw:
    homepage: https://github.com/xiaochuan886/xiaochuan886-skills
    requires:
      anyBins:
        - bun
        - npx
---

# OPC Markdown to HTML

Converts Markdown files to HTML with inline CSS, optimized for WeChat Official Account workflows and independently maintained by the OPC team.

## Script Directory

**Agent Execution**: Determine this SKILL.md directory as `{baseDir}`. Resolve `${BUN_X}` runtime: if `bun` installed → `bun`; if `npx` available → `npx -y bun`; else suggest installing bun. Replace `{baseDir}` and `${BUN_X}` with actual values.

| Script | Purpose |
|--------|---------|
| `scripts/setup.sh` | Install local dependencies |
| `scripts/main.ts` | Main entry point |

## Preferences (EXTEND.md)

Check EXTEND.md existence (priority order). Prefer the OPC namespace; keep the old path only as compatibility fallback:

```bash
# macOS, Linux, WSL, Git Bash
test -f .opc-skills/opc-markdown-to-html/EXTEND.md && echo "project"
test -f "${XDG_CONFIG_HOME:-$HOME/.config}/opc-skills/opc-markdown-to-html/EXTEND.md" && echo "xdg"
test -f "$HOME/.opc-skills/opc-markdown-to-html/EXTEND.md" && echo "user"
```

```powershell
# PowerShell (Windows)
if (Test-Path .opc-skills/opc-markdown-to-html/EXTEND.md) { "project" }
$xdg = if ($env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME } else { "$HOME/.config" }
if (Test-Path "$xdg/opc-skills/opc-markdown-to-html/EXTEND.md") { "xdg" }
if (Test-Path "$HOME/.opc-skills/opc-markdown-to-html/EXTEND.md") { "user" }
```

┌──────────────────────────────────────────────────────────────┬───────────────────┐
│                             Path                             │     Location      │
├──────────────────────────────────────────────────────────────┼───────────────────┤
│ .opc-skills/opc-markdown-to-html/EXTEND.md                   │ Project directory │
├──────────────────────────────────────────────────────────────┼───────────────────┤
│ $HOME/.opc-skills/opc-markdown-to-html/EXTEND.md             │ User home         │
└──────────────────────────────────────────────────────────────┴───────────────────┘

┌───────────┬───────────────────────────────────────────────────────────────────────────┐
│  Result   │                                  Action                                   │
├───────────┼───────────────────────────────────────────────────────────────────────────┤
│ Found     │ Read, parse, apply settings                                               │
├───────────┼───────────────────────────────────────────────────────────────────────────┤
│ Not found │ Use defaults                                                              │
└───────────┴───────────────────────────────────────────────────────────────────────────┘

**EXTEND.md Supports**: Default theme | Custom CSS variables | Code block style

## First-Time Setup

Run once in the script directory if dependencies are missing:

```bash
bash {baseDir}/scripts/setup.sh
```

## Workflow

### Step 0: Pre-check (Chinese Content)

**Condition**: Only execute if input file contains Chinese text.

**Detection**:
1. Read input markdown file
2. Check if content contains CJK characters (Chinese/Japanese/Korean)
3. If no CJK content → skip to Step 1

**Format Suggestion**:

If CJK content detected AND a markdown-formatting skill is available:

Use `AskUserQuestion` to ask whether to format first. Formatting can fix:
- Bold markers with punctuation inside causing `**` parse failures
- CJK/English spacing issues

**If user agrees**: Invoke your preferred markdown-formatting skill first, then use the formatted file as input.

**If user declines**: Continue with original file.

### Step 1: Determine Theme

**Theme resolution order** (first match wins):
1. User explicitly specified theme (CLI `--theme` or conversation)
2. EXTEND.md `default_theme` (this skill's own EXTEND.md, checked in Step 0)
3. Existing WeChat-posting skill EXTEND.md `default_theme` (compatibility fallback)
4. If none found → use AskUserQuestion to confirm

**Cross-skill EXTEND.md check** (only if this skill's EXTEND.md has no `default_theme`):

```bash
# Compatibility fallback: check an existing WeChat-posting skill EXTEND.md for default_theme
test -f "$HOME/.baoyu-skills/baoyu-post-to-wechat/EXTEND.md" && grep -o 'default_theme:.*' "$HOME/.baoyu-skills/baoyu-post-to-wechat/EXTEND.md"
```

```powershell
# PowerShell (Windows, compatibility fallback)
if (Test-Path "$HOME/.baoyu-skills/baoyu-post-to-wechat/EXTEND.md") { Select-String -Pattern 'default_theme:.*' -Path "$HOME/.baoyu-skills/baoyu-post-to-wechat/EXTEND.md" | ForEach-Object { $_.Matches.Value } }
```

**If theme is resolved from EXTEND.md**: Use it directly, do NOT ask the user.

**If no default found**: Use AskUserQuestion to confirm:

| Theme | Description |
|-------|-------------|
| `opc-briefing` (Recommended) | Default template. Information-dense, suited to policy and analysis articles |
| `opc-default` | Best all-round WeChat reading rhythm, based on `default` but more refined |
| `opc-editorial` | Slightly more magazine-like, suited to stories and case studies |
| `opc-salon` | Warm salon style with cards and dividers, suited to event recaps and roundtables |
| `opc-report` | Structured report style with clear section labels, suited to industry and trend analysis |
| `opc-notebook` | Notebook style with soft note blocks, suited to guides, frameworks, and how-tos |
| `opc-feature` | Warm feature-story style inspired by 135editor compositions, suited to founder stories and interviews |
| `opc-chapters` | Chapter-label style inspired by mdnice longform layouts, suited to serial essays and narrative analysis |
| `default` | Inherited classic layout for compatibility |
| `grace` | Inherited elegant layout |
| `simple` | Inherited minimal layout |
| `modern` | Inherited modern layout |

## Recommended Sets

### Primary Templates

- `opc-briefing`
- `opc-editorial`
- `opc-default`

### Backup Templates

- `opc-chapters`
- `opc-feature`
- `opc-report`

### Step 1.5: Determine Citation Mode

**Default**: Off. Do not ask by default.

**Enable only if the user explicitly asks** for "微信外链转底部引用", "底部引用", "文末引用", or passes `--cite`.

**Behavior when enabled**:
- Ordinary external links are rendered with numbered superscripts and collected under a final `引用链接` section.
- `https://mp.weixin.qq.com/...` links stay as direct links and are not moved to the bottom.
- Bare links where link text equals URL stay inline.

### Step 2: Convert

```bash
${BUN_X} {baseDir}/scripts/main.ts <markdown_file> --theme <theme> [--cite]
```

### Step 3: Report Result

Display the output path from JSON result. If backup was created, mention it.

## Usage

```bash
${BUN_X} {baseDir}/scripts/main.ts <markdown_file> [options]
```

**Options:**

| Option | Description | Default |
|--------|-------------|---------|
| `--theme <name>` | Theme name (`opc-default`, `opc-briefing`, `opc-editorial`, `opc-salon`, `opc-report`, `opc-notebook`, `opc-feature`, `opc-chapters`, `default`, `grace`, `simple`, `modern`) | `opc-briefing` |
| `--color <name\|hex>` | Primary color: preset name or hex value | theme default |
| `--font-family <name>` | Font: sans, serif, serif-cjk, mono, or CSS value | theme default |
| `--font-size <N>` | Font size: 14px, 15px, 16px, 17px, 18px | 16px |
| `--title <title>` | Override title from frontmatter | |
| `--cite` | Convert external links to bottom citations, append `引用链接` section | false (off) |
| `--keep-title` | Keep the first heading in content | false (removed) |
| `--help` | Show help | |

**Color Presets:**

| Name | Hex | Label |
|------|-----|-------|
| blue | #0F4C81 | Classic Blue |
| green | #009874 | Emerald Green |
| vermilion | #FA5151 | Vibrant Vermilion |
| yellow | #FECE00 | Lemon Yellow |
| purple | #92617E | Lavender Purple |
| sky | #55C9EA | Sky Blue |
| rose | #B76E79 | Rose Gold |
| olive | #556B2F | Olive Green |
| black | #333333 | Graphite Black |
| gray | #A9A9A9 | Smoke Gray |
| pink | #FFB7C5 | Sakura Pink |
| red | #A93226 | China Red |
| orange | #D97757 | Warm Orange (modern default) |

**Examples:**

```bash
# Basic conversion (uses opc-briefing theme, removes first heading)
${BUN_X} {baseDir}/scripts/main.ts article.md

# Policy / analysis layout
${BUN_X} {baseDir}/scripts/main.ts article.md --theme opc-briefing

# Case / feature layout
${BUN_X} {baseDir}/scripts/main.ts article.md --theme opc-editorial

# Theme with custom color
${BUN_X} {baseDir}/scripts/main.ts article.md --theme opc-default --color blue

# Enable bottom citations for ordinary external links
${BUN_X} {baseDir}/scripts/main.ts article.md --cite

# Keep the first heading in content
${BUN_X} {baseDir}/scripts/main.ts article.md --keep-title

# Override title
${BUN_X} {baseDir}/scripts/main.ts article.md --title "My Article"
```

## Output

**File location**: Same directory as input markdown file.
- Input: `/path/to/article.md`
- Output: `/path/to/article.html`

**Conflict handling**: If HTML file already exists, it will be backed up first:
- Backup: `/path/to/article.html.bak-YYYYMMDDHHMMSS`

**JSON output to stdout:**

```json
{
  "title": "Article Title",
  "author": "Author Name",
  "summary": "Article summary...",
  "htmlPath": "/path/to/article.html",
  "backupPath": "/path/to/article.html.bak-20260128180000",
  "contentImages": [
    {
      "placeholder": "MDTOHTMLIMGPH_1",
      "localPath": "/path/to/img.png",
      "originalPath": "imgs/image.png"
    }
  ]
}
```

## Themes

| Theme | Description |
|-------|-------------|
| `default` | Classic - traditional layout, centered title with bottom border, H2 with white text on colored background |
| `grace` | Elegant - text shadow, rounded cards, refined blockquotes (by @brzhang) |
| `simple` | Minimal - modern minimalist, asymmetric rounded corners, clean whitespace (by @okooo5km) |
| `modern` | Modern - large radius, pill-shaped titles, relaxed line height (pair with `--color red` for traditional red-gold style) |

## Supported Markdown Features

| Feature | Syntax |
|---------|--------|
| Headings | `# H1` to `###### H6` |
| Bold/Italic | `**bold**`, `*italic*` |
| Code blocks | ` ```lang ` with syntax highlighting |
| Inline code | `` `code` `` |
| Tables | GitHub-flavored markdown tables |
| Images | `![alt](src)` |
| Links | `[text](url)`; add `--cite` to move ordinary external links into bottom references |
| Blockquotes | `> quote` |
| Lists | `-` unordered, `1.` ordered |
| Alerts | `> [!NOTE]`, `> [!WARNING]`, etc. |
| Footnotes | `[^1]` references |
| Ruby text | `{base|annotation}` |
| Mermaid | ` ```mermaid ` diagrams |
| PlantUML | ` ```plantuml ` diagrams |

## Frontmatter

Supports YAML frontmatter for metadata:

```yaml
---
title: Article Title
author: Author Name
description: Article summary
---
```

If no title is found, extracts from first H1/H2 heading or uses filename.

## Extension Support

Custom configurations via EXTEND.md. See **Preferences** section for paths and supported options.

## References

Implementation notes and external inspirations are documented in [REFERENCES.md](REFERENCES.md).
