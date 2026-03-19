---
name: product-video-xhs-ops
description: Run an LLM-led end-to-end workflow for product video creation, Xiaohongshu publishing, trace-back, and operations logging around folders like 待完成/ that contain SKU images and core copy. Use when Codex should reason through creative direction, packaging realism, storyboard quality, publish copy, and trace strategy itself, while using lightweight scripts only to validate critical outputs and write the final Excel ledger under 已落盘/.
---

# Product Video XHS Ops

Use this skill when the task is a full video production and publishing workflow, but the creative and operational reasoning should remain model-driven instead of being hardcoded into one rigid orchestration script.

Important: `product-promo-video` is already the integrated generation engine.
Do not decompose its generation phase into separate homegrown steps unless you are debugging it.

## Principle

Prefer this division of labor:

- Let the LLM inspect the task folder, image, and copy.
- Let the LLM decide creative direction, packaging constraints, storyboard, and publish wording.
- Let scripts verify structural outputs and write deterministic files such as Excel ledgers.

Do not hand over the whole workflow to a single pipeline script unless the user explicitly wants a bulk batch fallback.

## Use with

Read and reuse these local skills:

- `/Users/re.stem/xiaochuan886-skills/skills/product-promo-video/SKILL.md`
- `/Users/luxiaochuan/.codex/skills/xiaohongshu-mcp/SKILL.md`
- `/Users/re.stem/xiaochuan886-skills/skills/xhs-publish-trace/SKILL.md`

Use these scripts selectively:

- `/Users/re.stem/xiaochuan886-skills/skills/product-video-xhs-ops/scripts/validate_campaign.py`
- `/Users/re.stem/xiaochuan886-skills/skills/product-video-xhs-ops/scripts/write_daily_ledger.py`
- `/Users/re.stem/xiaochuan886-skills/skills/product-video-xhs-ops/scripts/archive_task.py`
- `/Users/re.stem/xiaochuan886-skills/skills/product-video-xhs-ops/scripts/mcp_http_client.py`

Treat this as a legacy fallback only:

- `/Users/re.stem/xiaochuan886-skills/skills/product-video-xhs-ops/scripts/run_pipeline.py`

## Fixed paths

Default to these paths unless the user overrides them:

- 待处理任务目录: `${PWD}/待完成`
- 视频落盘根目录: `${PWD}/已落盘`
- 视频生成 skill: `<installed-skill-root>/product-promo-video`（仅用于定位脚本，不作为输出目录）
- 链接追踪 skill 参考: `<installed-skill-root>/xhs-publish-trace`

Assume each task folder such as `${PWD}/待完成/2` usually contains:

- 1 张 SKU 主图
- `文案.md`

## Recommended workflow

### 1. Read the task like a strategist, not like a batch job

For each task folder:

- inspect the image
- read `文案.md`
- decide whether the source image truly contains packaging
- decide whether the product is better represented by packaging, raw product, ingredient world, or product use scene

Do not default to packaging-centric visuals.

### 2. Let the LLM make the non-obvious decisions

The model should explicitly reason about:

- whether packaging exists in the source image
- whether any visible package text may remain in keyframes
- what the 2-segment narrative should be
- what each segment is responsible for
- what Xiaohongshu title/body/tags feel natural
- what query strings are most distinctive for trace-back

Do not reduce these decisions to fixed templates if the task has meaningful ambiguity.

### 3. Use `product-promo-video` for generation, but keep humans and validation in the loop

The primary generation path is:

```bash
python3 /Users/re.stem/xiaochuan886-skills/skills/product-promo-video/scripts/generate_campaign.py \
  --input-dir "/absolute/path/to/task-folder" \
  --platform "小红书" \
  --ratio "9:16" \
  --segment-duration 7 \
  --out-dir "/absolute/path/to/已落盘/YYYY-MM-DD/<task-id>"
```

This integrated command already covers:

- creative brief generation
- 2-segment storyboard generation
- 4 keyframe generation
- segment 1 video generation
- segment 2 video generation
- final concatenation
- `campaign-report.json` output

So the outer skill should not reimplement those generation stages.
The outer skill should only decide how to call this engine, review the output, and continue to publish/trace/log.

The default expectation is still a true 2-segment campaign:

- segment 1 video
- segment 2 video
- final concatenated video

After generation, validate structure with:

```bash
python3 /Users/re.stem/xiaochuan886-skills/skills/product-video-xhs-ops/scripts/validate_campaign.py \
  --report "/absolute/path/to/campaign-report.json"
```

This script verifies deterministic facts such as:

- report exists
- `segment_1_url` exists
- `segment_2_url` exists
- `final_video` exists
- all 4 keyframes exist

It does not judge creative quality for you.
It only checks whether the integrated `product-promo-video` output is structurally complete.

### 4. Perform visual review with the model before publishing

Before publishing, the model should inspect the generated keyframes and final video context and answer:

- Are there exactly 2 segments in the report?
- Did keyframes avoid invented text?
- If the source image had no packaging, did the keyframes avoid fabricating packaging?
- If packaging existed, is it faithful to the source image rather than invented?

Use scripts for existence checks.
Use the model for realism, provenance, and creative compliance checks.

Do not replace the integrated `generate_campaign.py` workflow with `generate_video.py` unless the task is explicitly a single-clip fallback or you are debugging generation failures.

### 5. Publish in a model-authored way

Use `xiaohongshu-mcp` and `mcp_http_client.py` as transport helpers, but let the model write:

- title
- body
- tags
- visibility choice when the user did not specify

Keep the publish payload simple and natural.
Do not blindly dump the campaign report into the post body.

### 6. Trace the public link using model judgment

Follow `xhs-publish-trace`, but let the model choose and reorder the best search queries from:

- title
- product name
- a distinctive body phrase
- a rare ingredient or category phrase

Only construct a public URL when `feed_id` and `xsec_token` are both verified.

### 7. Write the ledger only after facts are settled

When you have the real task outcome, write deterministic records with:

```bash
python3 /Users/re.stem/xiaochuan886-skills/skills/product-video-xhs-ops/scripts/write_daily_ledger.py \
  --daily-dir "/absolute/path/to/已落盘/YYYY-MM-DD" \
  --record "/absolute/path/to/task/pipeline-record.json"
```

Use this for:

- `daily-ledger.xlsx`
- `pipeline-summary.json`

The model should decide the record content first.
The script should only serialize it cleanly.

The record must include at least:

- `product_name`
- `video_name`
- `video_url`
- `likes`
- `collects`
- `comments`

Use `video_name` for the published video name or post title.
Use `video_url` for the traced public Xiaohongshu note URL once available.

## Minimal file contract per task

Keep these files under each dated task directory:

- `campaign-report.json`
- `pipeline-record.json`
- `campaign/final-campaign-*.mp4`
- `keyframes/seg1-start.png`
- `keyframes/seg1-end.png`
- `keyframes/seg2-start.png`
- `keyframes/seg2-end.png`
- `source-task/` after the task has been processed and moved out of `待完成`

## Archiving rule

After each task is processed, archive it immediately instead of waiting for the whole batch.

Use:

```bash
python3 /Users/re.stem/xiaochuan886-skills/skills/product-video-xhs-ops/scripts/archive_task.py \
  --task-dir "/absolute/path/to/待完成/<task-id>" \
  --output-dir "/absolute/path/to/已落盘/YYYY-MM-DD/<task-id>"
```

This move should happen once the task has a settled result for that run, so the same source folder is not picked up again from `待完成/`.

## Guardrails

- Do not silently downgrade a 2-segment task into a 1-segment deliverable.
- Do not invent packaging if the source image does not show packaging.
- Do not allow newly invented text in keyframes; only source-image packaging text may remain when packaging is truly visible.
- Do not treat scripts as the creative source of truth.
- Do not publish if the model has unresolved doubts about packaging provenance or keyframe text contamination.
- Do not fabricate a note link if tracing has not succeeded.
- Do not leave a completed task behind in `待完成/`; move it into that task's dated output folder immediately after the task run finishes.

## Fallback

If the user explicitly wants a fully automated bulk batch run, you may still use:

```bash
python3 /Users/re.stem/xiaochuan886-skills/skills/product-video-xhs-ops/scripts/run_pipeline.py
```

But this should not be the default operating mode for nuanced production work.

If `product-promo-video` itself fails, debug or rerun its integrated campaign path first.
Do not silently switch the user onto a one-segment generation path and pretend the result is equivalent.
