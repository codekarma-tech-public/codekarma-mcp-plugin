---
description: Cross-entity karmaIQ regression diff between two services or APIs. Manual slash invocation. Returns the same four-verdict output as the canary gate.
disable-model-invocation: true
argument-hint: "<service-a-or-api> <service-b-or-api>"
allowed-tools: mcp__karma-iq__regression_diff, mcp__karma-iq__get_time_intervals, mcp__karma-iq__get_system_overview
---

# Cross-entity diff: `$ARGUMENTS`

## Parse arguments

`$ARGUMENTS` should contain two tokens: side A and side B. Each may be:

- A service name (raw)
- An API node_id / interface_id (raw, regex-form path)

If only one token, ask for the missing side.

## Workflow

Delegate to the `karmaiq-canary-gate` subagent via the Task tool. Pass this prompt:

> Run a cross-entity regression_diff between side A = `$0` and side B = `$1` over the last 15 minutes. Pass both names raw — do NOT pre-resolve. Return verdict, top drivers, recommendation, and the pipeline JSON block.

If the user supplied a service-only on both sides (and they're different services), warn that whole-service cross-diff is **blocked** server-side: *"Whole-service cross-diff is not supported. Supply at least one api/interface_id on either side, or use `/karmaiq-promotion-gate:canary <svc>` for a single-service canary verdict."*

When the subagent returns, present output **verbatim**. Verdict is load-bearing — do not paraphrase.
