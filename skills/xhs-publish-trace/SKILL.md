---
name: xhs-publish-trace
description: Trace newly published Xiaohongshu notes back to their public links and retrieve available engagement metrics using xiaohongshu-mcp. Use this whenever the user asks to find a just-published Xiaohongshu note, reverse-search a note link from title/content, verify whether a post is public yet, or inspect note-level运营数据 such as likes, collects, comments, and comments list after publishing.
---

# XHS Publish Trace

Use this skill when the task is not "publish the post" itself, but "find it after publishing" or "read what data is available from the public note detail."

This skill is based on practical behavior observed from `xiaohongshu-mcp`:

- Newly published notes may not be searchable immediately.
- `仅自己可见` notes are usually not discoverable through the search flow.
- After switching a note to `公开`, the search + detail flow can usually recover the public note link.
- Public detail can reliably return likes, collects, comments, and comment list.
- Public detail does not reliably return view count / browse count.

## Use with

Read and follow:

- [$xiaohongshu-mcp](/Users/luxiaochuan/.codex/skills/xiaohongshu-mcp/SKILL.md)

Prefer its Python client:

- `/Users/luxiaochuan/.codex/skills/xiaohongshu-mcp/scripts/xhs_client.py`

Assume the local MCP server is already installed and the user may already be logged in.

## Goal

Complete one or both of these outcomes:

1. Recover the public Xiaohongshu note link for a recently published note.
2. Retrieve the note's currently available public engagement metrics.

## Workflow

### 1. Confirm the base connection

Check login first:

```bash
python3 /Users/luxiaochuan/.codex/skills/xiaohongshu-mcp/scripts/xhs_client.py status
```

If login fails, stop and tell the user the MCP session is not authenticated.

### 2. Gather the strongest search keys

Use the most unique identifiers first:

- exact title
- rare phrase from the body
- explicit AI disclosure phrase if present
- niche hashtags
- content type hint such as `--type 视频`

For newly published content, prefer latest sorting:

```bash
python3 /Users/luxiaochuan/.codex/skills/xiaohongshu-mcp/scripts/xhs_client.py search "<keyword>" --sort 最新 --type 视频 --json
```

Use multiple search phrases in parallel when possible:

- full title
- partial title
- one distinctive body phrase
- one disclosure phrase

### 3. Judge whether the note is discoverable yet

If the expected note does not appear:

- first suspect that the note is still `仅自己可见`
- otherwise suspect search indexing delay

Do not claim failure too early. Explain the likely cause:

- private note: search usually cannot reverse-find it
- public note: may need a short delay before search finds it

### 4. Extract the link ingredients

From search results, capture:

- `feed_id`
- `xsec_token`

Then verify using detail:

```bash
python3 /Users/luxiaochuan/.codex/skills/xiaohongshu-mcp/scripts/xhs_client.py detail <feed_id> "<xsec_token>" --json
```

Confirm the note by matching:

- title
- author nickname
- content snippet
- note type

### 5. Construct the public link

When both values are present, build the link as:

```text
https://www.xiaohongshu.com/explore/<feed_id>?xsec_token=<urlencoded_xsec_token>&xsec_source=pc_feed
```

Always return the final link in clickable form.

## Available metrics

From `detail`, expect these public interaction fields when available:

- `likedCount`
- `collectedCount`
- `commentCount`
- sometimes `sharedCount`
- comment list and per-comment likes

Present them using user-friendly labels:

- 点赞
- 收藏
- 评论
- 分享

## Unavailable or unreliable metrics

Do not promise these unless the actual response contains them:

- 浏览量
- 阅读量
- 查看量

If the user asks for view count and the response does not contain it, say clearly that this MCP currently exposes public interaction metrics, not creator-backend traffic metrics.

## Reporting format

When a note is found, respond in this order:

1. state clearly that the note was found
2. provide the final public link
3. list title, author, note type
4. list current engagement metrics
5. mention any unavailable metrics

Use a compact format like:

```markdown
找到了，这就是目标笔记。

- 链接：[...](...)
- 标题：...
- 作者：...
- 类型：视频
- 点赞：0
- 收藏：0
- 评论：0
- 说明：当前接口未返回浏览量
```

When a note is not found, explain the most likely blocker and the next best action:

- switch note to `公开`
- wait a few minutes and retry
- copy the in-app share link as fallback

## Guardrails

- Do not invent a link without both `feed_id` and `xsec_token`.
- Do not claim a note is unpublished only because search missed it once.
- Do not present private-only assumptions as facts.
- If multiple similar notes appear, verify with detail before returning a link.

## Example search progression

For a new video post:

1. search exact title with `--type 视频 --sort 最新`
2. search a unique phrase from the body
3. search the AI disclosure phrase if one exists
4. verify the best candidate with `detail`
5. build and return the public link

## Example outcome

Observed successful reverse-trace pattern:

- title search found the note after it was switched to public
- result included `feed_id` and `xsec_token`
- `detail` confirmed title, author, and body
- public link could then be constructed successfully
