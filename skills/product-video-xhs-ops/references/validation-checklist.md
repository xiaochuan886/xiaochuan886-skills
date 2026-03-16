# Validation Checklist

Use the model to judge semantic correctness and scripts to judge deterministic structure.

## Model-reviewed checks

1. Does the source image clearly show packaging?
2. If no packaging is visible, did the generated keyframes avoid inventing bottles, boxes, bags, labels, or packaging text?
3. If packaging is visible, is the visible packaging faithful to the source image?
4. Do the keyframes avoid newly invented text, subtitles, badges, and watermarks?
5. Do segment 1 and segment 2 have different narrative responsibilities?
6. Does the publish copy sound native to Xiaohongshu instead of templated?

## Script-reviewed checks

1. `campaign-report.json` exists
2. `segment_1_url` exists
3. `segment_2_url` exists
4. `final_video` exists
5. 4 keyframe files exist
6. `pipeline-record.json` is valid JSON
7. `daily-ledger.xlsx` writes successfully
