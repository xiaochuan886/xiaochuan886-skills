---
name: product-promo-video
description: Generate product promo videos from product images and product descriptions for social media growth. Use this when the user wants an AI product advertisement, product showcase, short-form promo clip, 带货视频, 社媒引流视频, or marketing video based on a product photo plus product copy, especially when the style should follow same-category competitor best-seller trends without copying a specific brand. Supports 9:16 vertical and 16:9 horizontal output, but each task must use one ratio consistently.
---

# Product Promo Video

Use this skill when the goal is not a generic AI video, but a short-form product promotion clip designed for social media distribution and lead generation.

This skill turns:

- one or more product images
- a product description or a material folder containing image plus copy
- optional audience, platform, and category hints

into:

- a trend-aware creative brief
- a two-segment storyboard with linked narration intent
- a high-quality Seedance prompt authored from that storyboard
- a full 2-segment production workflow when needed
- one final concatenated campaign video

The full campaign workflow must stay a 2-segment workflow:

- segment 1 video
- segment 2 video
- one final concatenated video

Do not silently downgrade a campaign request into a single clip.

## Use With

Use the scripts in this skill:

- `/Users/re.stem/xiaochuan886-skills/skills/product-promo-video/scripts/build_prompt.py`
- `/Users/re.stem/xiaochuan886-skills/skills/product-promo-video/scripts/generate_video.py`
- `/Users/re.stem/xiaochuan886-skills/skills/product-promo-video/scripts/generate_campaign.py`
- `/Users/re.stem/xiaochuan886-skills/skills/product-promo-video/scripts/concat_segments.py`
- `/Users/re.stem/xiaochuan886-skills/skills/product-promo-video/references/physical-realism.md`

Environment file for this skill:

- `/Users/re.stem/xiaochuan886-skills/skills/product-promo-video/.env`
- `/Users/re.stem/xiaochuan886-skills/skills/product-promo-video/.env.example`

Treat the script as a scaffold generator, not the final creative brain.
The final prompt should be upgraded by the model after reasoning about product, audience, trend, and conversion intent.

If the user supplies a local image path and visual details matter, inspect the image before writing the prompt.
When motion realism matters, read `/Users/re.stem/xiaochuan886-skills/skills/product-promo-video/references/physical-realism.md`.

## Setup

Before first use:

```bash
cp /Users/re.stem/xiaochuan886-skills/skills/product-promo-video/.env.example \
   /Users/re.stem/xiaochuan886-skills/skills/product-promo-video/.env
```

Then edit `.env` and fill in:

```text
SKYLARK_API_KEY=你的火山引擎 API Key
```

`generate_video.py` will load this file automatically.

## Goal

Produce a mobile-first product promo video that feels like a strong same-category best-seller trend:

- fast first-second hook
- premium product hero framing
- clear benefit reveal
- visual motion suitable for short video feeds
- ending that feels conversion-oriented

The target default is:

- duration: `15` seconds
- ratio: `9:16`
- resolution: `720p`

Supported ratios:

- `9:16` for mobile-first vertical distribution
- `16:9` for horizontal distribution

For one task, choose exactly one ratio and keep both segments in that same ratio.
Do not mix vertical and horizontal clips inside one final deliverable.

## Inputs

Collect or infer these inputs:

- product image path or public image URL
- product description, or a material folder such as `/path/to/task-folder`
- product category
- target audience
- optional platform such as Xiaohongshu, Douyin, Instagram Reels, TikTok
- optional tone such as premium, clean, cute, tech, luxury, minimal

If category or audience is not given, infer them from the product description and image.
If the user gives a folder, read the folder first:

- find the SKU image
- read `文案.md` or other text files if present
- if the copy file is empty, infer visible selling points from the image
- generate a normalized material summary before writing the storyboard

## Workflow

### 1. Extract the marketing core

Summarize the product into five pieces:

- what the product is
- who it is for
- one primary selling point
- one emotional hook
- one visual hook

Keep this short and concrete.

### 2. Do Baoyu-style creative expansion before writing the prompt

Do not jump directly from product description to one generic prompt.

First expand the idea across these dimensions:

- **Product role**: hero object, lifestyle companion, ritual object, premium gift, problem-solver
- **Audience fantasy**: efficient upgrade, self-care moment, status display, aesthetic pleasure, convenience win
- **Trend language**: clean macro, punchy reveal, texture-first, cinematic lifestyle, luxury unboxing, fast feed hook
- **Scene direction**: pure studio, stylized lifestyle, dramatic close-up world, tactile material space
- **Motion rhythm**: slow premium, punchy cut, elegant glide, energetic reveal
- **Conversion energy**: subtle desire, strong种草, direct带货, premium aspiration

Usually generate 2-3 candidate directions mentally, then choose the strongest one for the actual prompt.
Do not show all candidates unless the user asks for options.

### 3. Translate “competitor best-seller trend” into safe style signals

Do not imitate a named brand, logo, slogan, packaging, or distinctive campaign.

Instead, abstract the trend into generic signals such as:

- clean macro close-ups
- glossy lighting sweeps
- floating particles or petals
- quick punch-in transitions
- beauty-product liquid motion
- lifestyle handheld realism
- luxury unboxing rhythm
- bold textless product hero ending

Use category-appropriate motion language:

- beauty/skincare: glow, serum texture, soft highlights, water droplets
- jewelry/luxury: velvet shadow, sparkle, slow turntable, elegant reveal
- food/drink: splash, condensation, appetite close-up, fast energy cuts
- electronics: sharp reflections, precision details, futuristic light streaks
- home goods: cozy light, tactile material detail, calm lifestyle atmosphere

### 4. Build the structure

For a single clip, write the prompt as a single continuous cinematic instruction that implies this beat structure:

1. `0-3s` Hook: immediate eye-catching reveal
2. `3-7s` Product focus: hero angle and core feature
3. `7-11s` Benefit escalation: texture, use scene, or transformation
4. `11-15s` Conversion ending: premium hero shot with purchase intent energy

Prefer visual storytelling over text overlays unless the user explicitly asks for on-screen text.

When the task needs a longer campaign, split it into two clips with complementary shot plans.
Example split:

- clip 1: close-up / medium-close product hook
- clip 2: medium / wide environmental trust shot and final hero composition

Also pre-design one sentence of intended spoken copy for each segment.
The two lines should:

- not repeat each other
- carry a clear narrative handoff
- map to the shot responsibility of each segment

### 4.5. Add physical realism constraints for image-to-video

When animating from a product image, the prompt should preserve coherence:

- let the image define composition and appearance
- use the text mainly to define motion
- choose one primary action and one simple camera move
- keep background, lighting, and scale relationships stable unless change is intentional
- respect gravity, inertia, and material behavior

Prefer physically plausible motion such as:

- gentle push-in
- slight orbit
- breeze moving leaves or hair
- dew sliding downward
- liquid gathering and flowing with gravity
- subtle hand movement with stable grip

Avoid overloading one clip with multiple impossible changes.

If the shot includes pouring into a cup or glass container:

- treat the container as a sealed solid object
- let liquid enter only through the visible opening
- keep the cup bottom and side walls intact
- let the liquid level change only inside the container
- avoid dramatic splashes unless the source image already supports that energy

### 4.6. Respect packaging and text provenance

Treat the source image as the authority for whether packaging exists.

- If the source image clearly contains a bottle, bag, box, can, pouch, or other product packaging, preserve that visible packaging faithfully.
- If the source image does not clearly contain packaging, do not invent packaging, labels, bottles, bags, boxes, cans, or sticker graphics.
- Keyframe images must not contain any newly invented text.
- The only text allowed in keyframes is text that already physically exists on visible packaging in the source image.
- Do not add subtitles, slogans, badges, watermark-like labels, or faux brand marks to keyframes.

### 5. Generate a creative brief first, then write the two-segment storyboard

Use the helper script when possible:

```bash
python3 /Users/re.stem/xiaochuan886-skills/skills/product-promo-video/scripts/build_prompt.py \
  --image "/absolute/path/to/product.jpg" \
  --description "产品描述" \
  --category "品类" \
  --audience "目标人群" \
  --platform "小红书" \
  --segment-duration 7
```

The script prints:

- a structured brief
- a two-segment storyboard
- a prompt draft

The storyboard is the real control layer.
Write the campaign as two linked segments first, then derive the keyframe prompts and video prompts from that script.

The final prompt should feel authored, not auto-filled:

- sharpen weak phrases
- remove repetition
- make motion and camera directions more vivid
- make the emotional payoff and conversion intent more specific
- preserve the product as the central visual anchor
- preserve physical plausibility and spatial continuity

### 6. Prompt quality bar

The final prompt should usually include:

- the product as the visual hero
- a specific camera language
- lighting style
- material or texture detail
- category-relevant motion cues
- social-media-ready pacing
- a strong ending composition
- an implied reason this product feels worth buying now

Prefer vivid, filmable language over abstract ad copy.
For image-to-video, prefer simple, direct motion instructions over dense conceptual language.
For keyframes, explicitly state that no new text may appear and no packaging may be fabricated.

### 7. Run the integrated generator

For a local image:

```bash
python3 /Users/re.stem/xiaochuan886-skills/skills/product-promo-video/scripts/generate_video.py \
  --image-base64 "/absolute/path/to/product.jpg" \
  --description "这里填产品描述" \
  --audience "这里填目标人群" \
  --platform "小红书" \
  --ratio 9:16
```

For a public image URL:

```bash
python3 /Users/re.stem/xiaochuan886-skills/skills/product-promo-video/scripts/generate_video.py \
  --image-url "https://example.com/product.jpg" \
  --description "这里填产品描述" \
  --audience "这里填目标人群" \
  --platform "小红书" \
  --ratio 16:9
```

If you already have a polished prompt and want to bypass auto-briefing:

```bash
python3 /Users/re.stem/xiaochuan886-skills/skills/product-promo-video/scripts/generate_video.py \
  --image-base64 "/absolute/path/to/product.jpg" \
  --prompt "这里填你已经写好的提示词" \
  --ratio 9:16
```

### 8. Concatenate two generated segments

When the user wants two clips stitched into one final video, generate both clips with the same ratio, then concatenate them:

```bash
python3 /Users/re.stem/xiaochuan886-skills/skills/product-promo-video/scripts/concat_segments.py \
  --video-url-1 "第一段视频链接" \
  --video-url-2 "第二段视频链接" \
  --out-dir "/absolute/output/dir"
```

This workflow does not add subtitles or external narration.
Use the original generated video audio only.

### 9. End-to-end workflow

For the full workflow, prefer the integrated campaign generator.
It will:

1. generate a creative brief
2. generate a two-segment storyboard
3. derive 4 keyframes from that storyboard with `baoyu-image-gen`
4. derive 2 video prompts from the same storyboard
5. generate 2 video segments
6. concatenate both segments into one final video

It accepts either:

- a local product image path
- a public product image URL

If `--out-dir` is omitted, it writes to a timestamp-free default folder under the current working directory:

- `${PWD}/output/`

Default naming rule:

- direct image input: `<category>-<ratio>`
- folder input: `<folder-name>-<category>-<ratio>`

This keeps each task isolated and avoids overwriting previous runs from other folders.

```bash
python3 /Users/re.stem/xiaochuan886-skills/skills/product-promo-video/scripts/generate_campaign.py \
  --input-dir "/absolute/path/to/task-folder" \
  --audience "这里填目标人群" \
  --platform "小红书" \
  --ratio 16:9 \
  --segment-duration 7
```

Or with a public image URL:

```bash
python3 /Users/re.stem/xiaochuan886-skills/skills/product-promo-video/scripts/generate_campaign.py \
  --image "https://example.com/product.jpg" \
  --description "这里填产品描述" \
  --platform "小红书" \
  --ratio 9:16
```

This is the preferred path when the user wants the skill to complete the full workflow end-to-end.
The final report will also save the storyboard, both spoken-copy lines, both video prompts, and all asset paths.
When using `--input-dir`, it also saves the resolved image path, loaded text files, and visual-analysis result.

## Baoyu Integration

This skill relies on `baoyu-image-gen` for keyframe generation when running the full workflow.

Important environment note:

- `baoyu-image-gen` itself auto-loads `~/.baoyu-skills/.env`
- this skill also supports loading `~/.baoyu-skills/baoyu-image-gen/.env` and injecting those keys into the image-generation subprocess

That avoids the common case where keys exist but `baoyu-image-gen` does not see them by default.

## Prompt Rules

The generated prompt should usually include:

- the product as the visual hero
- camera movement
- lighting style
- material or texture detail
- category-relevant motion cues
- social-media-ready pacing
- a strong ending composition
- a clear conversion feeling
- explicit continuity and realism cues when the shot starts from a real image

Avoid:

- named competitor brands
- copyrighted characters
- giant blocks of text on screen
- impossible scene changes that distract from the product
- asking the model to show UI buttons, app screenshots, or readable tiny copy unless required
- impossible object deformation without visual cause
- too many simultaneous camera moves in a single short clip
- liquid, fruit, or hand motion that ignores gravity or contact points

## Output Format

When completing the task, provide:

1. a short creative direction summary
2. the final Seedance prompt
3. the exact command used
4. the resulting video URL if generation succeeds

When useful, also provide a compact creative brief:

- category
- audience
- trend direction
- emotional hook
- visual hook
- conversion strategy

## Example Prompt Shape

Use this style as a pattern, not a fixed template:

```text
以产品实物为主角，竖屏 9:16，15 秒社交媒体爆款广告节奏，开场 1 秒即高能吸睛特写，镜头快速推进，光影掠过产品表面，突出材质与核心卖点；随后切换多角度近景与中景，展示使用场景和细节变化，整体风格高级、干净、利落，符合该品类热门带货短视频趋势；中段强化质感、功能和情绪价值，画面流畅、有层次、有购买冲动；结尾定格产品 hero shot，氛围精致，具备明显种草和转化感，无文字水印，无品牌模仿。
```

## Guardrails

- If the user asks to copy a specific competitor ad exactly, refuse the copying part and offer a trend-inspired version instead.
- If only text is available and no image exists, say the output quality is likely lower and ask whether to proceed with text-to-video.
- Prefer one clear hero product over cluttered multi-product scenes unless the user explicitly wants a bundle.
- If the first prompt sounds generic, rewrite it before generating. Do not settle for bland prompt language.
- If the first prompt implies implausible motion, simplify it before generating.
