# Output Layout

Use this layout for each run date:

```text
已落盘/
└── YYYY-MM-DD/
    ├── daily-ledger.xlsx
    ├── pipeline-summary.json
    ├── 1/
    │   ├── campaign-report.json
    │   ├── pipeline-record.json
    │   ├── source-task/
    │   ├── campaign/
    │   └── keyframes/
    └── 2/
        ├── campaign-report.json
        ├── pipeline-record.json
        ├── source-task/
        ├── campaign/
        └── keyframes/
```

Recommended workbook sheets:

1. `Summary`
2. `Tasks`

Recommended `Tasks` columns:

1. `run_date`
2. `task_id`
3. `product_name`
4. `video_name`
5. `video_url`
6. `source_dir`
7. `image_path`
8. `copy_path`
9. `output_dir`
10. `report_path`
11. `final_video`
12. `category`
13. `summary`
14. `publish_title`
15. `publish_body`
16. `publish_tags`
17. `visibility`
18. `video_status`
19. `publish_status`
20. `trace_status`
21. `note_url`
22. `feed_id`
23. `xsec_token`
24. `likes`
25. `collects`
26. `comments`
27. `shares`
28. `error`

Keep all paths absolute.
