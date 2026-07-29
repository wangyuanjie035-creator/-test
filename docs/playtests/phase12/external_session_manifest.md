# Phase 12 external first-exposure session manifest

Status: ready to recruit; completed external sessions `0/16`.

Each row requires a different person who has not previously seen or played the
game. `participant_id` is an anonymous session token, not a name or contact
identifier. Do not reorder or replace Seeds after recruitment begins.

| Test ID | Anonymous participant ID | Seed | Topic | Locked candidates |
|---|---|---:|---|---|
| P12-EXT-001 | anon-ext-001 | 244002 | clean_data_topic | unattended, all_nighter, converter |
| P12-EXT-002 | anon-ext-002 | 244003 | chart_topic | unattended, parameter_scan, auto_stats |
| P12-EXT-003 | anon-ext-003 | 244004 | literature_topic | unattended, subscription, all_nighter |
| P12-EXT-004 | anon-ext-004 | 244008 | literature_topic | crawler, batch_experiment, converter |
| P12-EXT-005 | anon-ext-005 | 244011 | chart_topic | crawler, batch_experiment, auto_stats |
| P12-EXT-006 | anon-ext-006 | 244012 | literature_topic | parameter_scan, cleaning, unattended |
| P12-EXT-007 | anon-ext-007 | 244013 | experiment_topic | batch_experiment, unattended, auto_stats |
| P12-EXT-008 | anon-ext-008 | 244017 | experiment_topic | cleaning, auto_stats, batch_experiment |
| P12-EXT-009 | anon-ext-009 | 244025 | experiment_topic | unattended, crawler, batch_experiment |
| P12-EXT-010 | anon-ext-010 | 244026 | clean_data_topic | subscription, auto_stats, batch_experiment |
| P12-EXT-011 | anon-ext-011 | 244030 | clean_data_topic | auto_stats, unattended, converter |
| P12-EXT-012 | anon-ext-012 | 244032 | literature_topic | loop_guard, unattended, all_nighter |
| P12-EXT-013 | anon-ext-013 | 244034 | clean_data_topic | unattended, converter, cleaning |
| P12-EXT-014 | anon-ext-014 | 244055 | chart_topic | crawler, unattended, all_nighter |
| P12-EXT-015 | anon-ext-015 | 244069 | experiment_topic | loop_guard, unattended, cleaning |
| P12-EXT-016 | anon-ext-016 | 244082 | clean_data_topic | cleaning, subscription, batch_experiment |

## Launch template

Replace the four values with the values from exactly one manifest row:

```text
Godot.exe --path <project> -- \
  --blind-test-id=P12-EXT-001 \
  --blind-participant-id=anon-ext-001 \
  --blind-record-path=res://docs/playtests/phase12/sessions/P12-EXT-001.jsonl \
  --blind-expected-seed=244002
```

Before the participant starts, verify that no file already exists for the test
ID. A duplicate ID is rejected by the recorder; never delete or overwrite a
completed record to rerun the same participant.

## Facilitator order

1. Launch the assigned row and let the participant close the help page.
2. Ask only: “三张候选里，你现在最想安装哪张？请边想边说。”
3. Freeze their first choice and unprompted words before asking anything else.
4. Let them choose overclock/maintenance if desired and press `开始一天`.
5. After Day 1 resolves, ask neutral questions:
   - “你刚才注意到哪些候选之间的区别？”
   - “你原本预期今天会发生什么？和实际哪里一样或不一样？”
6. Only after those answers are frozen may the structured follow-up ask about
   today versus Day 3–4.
7. Copy the spoken answers into a fresh `record_template.json` copy associated
   with the same test ID. Do not edit the machine JSONL row.
