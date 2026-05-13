---
description: Run the karmaIQ canary regression gate on a single service over the last 15 minutes. Manual slash invocation. Returns the verdict (STABLE / WATCH / REGRESSION / INSUFFICIENT_DATA) and a pipeline-ready JSON block.
disable-model-invocation: true
argument-hint: "<service-name> [duration-minutes]"
allowed-tools: mcp__karma-iq__regression_diff, mcp__karma-iq__get_time_intervals, mcp__karma-iq__get_system_overview
---

# Canary gate on `$ARGUMENTS`

## Parse arguments

- First token: service name (raw — do **not** pre-resolve)
- Second token (optional): duration in minutes; defaults to 15

## Workflow

Delegate to the `karmaiq-canary-gate` subagent via the Task tool. Pass this prompt:

> Run the canary regression gate on `$ARGUMENTS`. Use the second token as `duration_minutes` if present, otherwise 15. Return the verdict, top drivers, recommendation, and the pipeline JSON block. Pass the service name raw — do NOT pre-resolve via search_catalog.

When the subagent returns, present its output **verbatim**. Do not paraphrase the verdict. Do not summarize the JSON block — it must be parseable for pipelines.
