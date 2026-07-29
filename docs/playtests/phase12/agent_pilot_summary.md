# Phase 12 Agent pilot summary

Date: 2026-07-23  
Status: workflow PASS; formal player verdict remains INCONCLUSIVE  
Scope: eight workflow/debugging pilots. These rows are not human data and are
excluded from every Phase 12 percentage.

## Method

- Each run used a locked preregistered Seed and its real Day 1 game screen.
- The experience agent saw only the screenshot. It was explicitly prohibited
  from reading the preregistration table, route search, or game code.
- Three perspectives were rotated: systems planner, first-exposure UI reader,
  and risk-averse experienced player.
- The agent stated an unprompted first choice, expectation, acceptable
  alternative, and confidence before the game was clicked remotely.
- The attached recorder captured the real first confirmation and Day 1 result.
- Decision time is retained as a recorder integrity check only. Agent
  orchestration latency makes it invalid as a player-speed measurement.

## Runs

| Test ID | Seed | First choice | Perspective | Confidence | Acceptable alternative | Day 1 paper |
|---|---:|---|---|---:|---|---:|
| P12-AGENT-001 | 244002 | 夜间无人值守 | systems | 4 | 祖传转换脚本 | 5 |
| P12-AGENT-002 | 244003 | 参数扫描 | UI first-exposure | 3 | 自动统计 | 0 |
| P12-AGENT-003 | 244004 | 关键词订阅 | risk-averse | 4 | 夜间无人值守 | 0 |
| P12-AGENT-004 | 244008 | 批量实验脚本 | systems | 4 | 文献爬虫 | 5 |
| P12-AGENT-005 | 244011 | 批量实验脚本 | UI first-exposure | 4 | 文献爬虫 | 5 |
| P12-AGENT-006 | 244012 | 夜间无人值守 | risk-averse | 4 | 自动清洗管线 | 0 |
| P12-AGENT-007 | 244013 | 批量实验脚本 | systems | 5 | 夜间无人值守 | 5 |
| P12-AGENT-008 | 244017 | 批量实验脚本 | UI first-exposure | 4 | 自动清洗管线 | 5 |

Machine evidence is stored as one JSONL file per test ID in
`docs/playtests/phase12/sessions/`.
Frozen pre-click reasoning, expectations, alternatives, and confidence are
transcribed by test ID in `agent_pilot_observations.md`. They intentionally
remain separate from the automatic JSONL row; the latter is never presented as
having captured speech.

## Evidence index

All hashes are SHA-256 after the documented sample-classification migration.

| Test ID | Screenshot path | Screenshot SHA-256 | JSONL SHA-256 |
|---|---|---|---|
| P12-AGENT-001 | `evidence/agent_pilot/P12-AGENT-001-choice-screen.png` | `bb0aea42e508588a58c256ba2e4ff9d0fa586128809b4a0f9af94e891e9d906d` | `bcca4889fddcf987e6c48196328c67f72df432cd09fa50525dd6ddf0e2016baa` |
| P12-AGENT-002 | `evidence/agent_pilot/P12-AGENT-002-choice-screen.png` | `50d2bfa16c23bdb5ae006c9dd4f41d2ff8cde326c5c26ef6fcf77e3b90802765` | `32feb8047680a42b4091e903db6d2be895d53614de740a4bd423b37d54880814` |
| P12-AGENT-003 | `evidence/agent_pilot/P12-AGENT-003-choice-screen.png` | `62566fb6c19fa485e8a010d2d6dacb5c5eca2d8feb5949e9cd3e78ba803735c8` | `8c3de26b86ba2cf66fa5a57d55f24028517c09533dce8d70d7c0b48bf52addf4` |
| P12-AGENT-004 | `evidence/agent_pilot/P12-AGENT-004-choice-screen.png` | `92e6b7fc2076fce03c91756480292dfb949e0752f620f610cc1e1835cf6f2fe1` | `6e4f3be3af9d62fb97290d3d40c218e30fd6319219c75591453d75b10ac5cef0` |
| P12-AGENT-005 | `evidence/agent_pilot/P12-AGENT-005-choice-screen.png` | `9f64cb37c513b57296a69cae08facdad36db39a78c7c0353cc9010fa608b03ac` | `4d1a96583d944a8c9aa16c7d0b9579f92f3eb744779d73c602ddee8830e91706` |
| P12-AGENT-006 | `evidence/agent_pilot/P12-AGENT-006-choice-screen.png` | `dd4013b441ec7ba22cd1f8959d618c9ac9eccfec1b10f191130ee26c8a3c8a1f` | `ead9583f67e89e96f62be87a4ace48032d4b8ed3c64b7e4e1a15d62f8ce146f5` |
| P12-AGENT-007 | `evidence/agent_pilot/P12-AGENT-007-choice-screen.png` | `28eef451616e932758235a86169ab78f01f2b2fe989577f2c20eb875c4b1bf27` | `9e7a54e4271098d246688cb9d58d2a10a238cadd24000b36ab9b59016cf8cd0c` |
| P12-AGENT-008 | `evidence/agent_pilot/P12-AGENT-008-choice-screen.png` | `37a5af682b6db74185bcf3c96e3061d4aa81ce875fcb7ab5b8b7cf053daeb5c7` | `2fb32e574483bd7c368aaa638892466be4c3621e2c74c277360ff0ae7a326f19` |

## Workflow findings

The workflow is suitable for the external first-exposure test:

- 8/8 runs armed the recorder with the intended Seed.
- 8/8 displayed the locked three-candidate set and locked topic.
- 8/8 captured a first confirmation, submitted choice, automatic timing,
  Day 1 result, and post-choice state.
- 8/8 agents could place their chosen card on the visible production chain.
- 8/8 machine rows are classified `agent_pilot`; aggregation must exclude them
  from external first-exposure statistics.
- Agents selected experiment, literature, and delayed automation candidates;
  the pilot did not collapse into one mandatory first click.

The following are interview targets, not UI-change decisions:

1. Does an installed card run on the installation day?
2. Does installation replace the basic workstation or stack with it?
3. What exactly counts as “处理两批”?
4. Does a cumulative topic count production or end-of-day inventory?
5. In what order do workstations resolve during a day?

These uncertainties appeared naturally and should be captured in the neutral
follow-up. The facilitator must not explain them before freezing the
unprompted answer.

## Gate

Agent pilot gate: **PASS**.

This result validates the test process only. It does not validate player
comprehension, candidate balance, or the current UI. The formal Phase 12 state
is **INCONCLUSIVE** until at least 16 external first-exposure records satisfy
the preregistered exposure and blind-coding requirements.
