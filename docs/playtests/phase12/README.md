# Phase 12 playtest evidence

This directory stores the preregistered Seed table and first-choice comprehension records.

Operational files:

- `agent_pilot_summary.md`: eight workflow-only pilot results.
- `external_session_manifest.md`: frozen 16-person external session assignment
  and facilitator order.
- `record_template.json`: one fresh human-observation copy per external test ID.

Rules:

- `preregistered_seeds.json` is generated only by the opening counterfactual audit at beam width 512.
- Do not edit the preregistered table after participants see a test screen.
- Copy `record_template.json` once per test ID; never overwrite a completed participant record.
- Keep Agent pilot, external first exposure, learning retest, and negative control records in separate summaries.
- Evidence paths, Seed, candidate IDs, timestamps, and the record row must share the same test ID.
- The unprompted block is frozen before any neutral or structured follow-up.
- Two independent coders score external first-exposure records before disagreements are resolved.

## Locked preregistration

`preregistered_seeds.json` was generated from Seeds `244000–244099` at beam width
512.  Mechanical validation passed:

- 16 selected rows and 16 unique Seeds;
- non-experiment slots 0 / 2 / 3 have 4 / 4 / 7 eligible exposures;
- every selected non-experiment branch can win and has regret at most 5;
- every corresponding global route can win.

Do not replace a selected Seed because its choice screen appears inconvenient.

## Automatic blind-test recording

The main scene contains a removable recorder node which is completely inert
unless all four arguments below are supplied after `--`:

```text
--blind-test-id=P12-EXT-001
--blind-participant-id=anon-001
--blind-record-path=res://docs/playtests/phase12/sessions/P12-EXT-001.jsonl
--blind-expected-seed=244002
```

When armed, the recorder:

1. starts the exact expected Seed;
2. waits until the help/settings overlays are closed and all three candidates
   are interactable;
3. records the first candidate confirmation time automatically;
4. records the submitted choice, Day 1 result, and post-choice state after
   `开始一天`;
5. writes one verified JSONL row under the Phase 12 sessions directory.

The automatic row is the machine evidence companion to `record_template.json`.
The facilitator still freezes the player's unprompted words before any neutral
or structured follow-up. Never put names, email addresses, or other identifying
information in `participant_id`.
