---
description: Diagnose production incidents end-to-end via karmaIQ. Loads when the user reports API errors, 5xx, slow endpoints, latency spikes, p99 regressions, alerts firing, error chains, exception types, customer complaints, or 'something is broken in prod'. Delegates multi-step root-cause investigation to the karmaiq-firefighter subagent so the main conversation stays clean.
allowed-tools: mcp__karma-iq__*
---

# Firefighting production incidents

The user is reporting (or describing) a live production problem. Switch into karmaIQ incident-response mode.

## Decide: subagent or inline

**Delegate to the `karmaiq-firefighter` subagent (preferred for real incidents).** Use the Task tool with `subagent_type=karmaiq-firefighter` whenever:

- The investigation will require 3+ karmaIQ tool calls
- The user described symptoms but not a precise interface_id
- You need to walk both graph layer (latency, error %) and code-path layer (exception types)
- The user asked "why" or "what's causing"

The subagent has the W1 workflow built-in and returns a focused summary instead of flooding this conversation with intermediate tool output. Pass the user's description **verbatim** as the subagent's prompt.

**Stay inline only when:**

- Single-shot question ("what's the error rate on X right now")
- User already has an exact `interface_id`
- User explicitly asks you not to delegate

## Inline workflow (when not delegating)

Standard W1:

1. `mcp__karma-iq__get_time_intervals(duration_minutes=720, num_windows=12)` — find when
2. `mcp__karma-iq__search_catalog(catalog="graph", query="<user-mentioned name>")` — resolve `node_id`
3. `mcp__karma-iq__get_api_deep_dive(interface_id="<exact>", epochStartTime=..., epochEndTime=...)` — pinned RCA
4. Follow TIPs. `root_cause_candidates` for upstream blame. `diagnose_code_path_errors` for exception types.

Read the active domain from `${CLAUDE_PLUGIN_DATA}/../karmaiq-core/domain.txt`. Pass `domain=...` on every call.

## Output template (every analytical answer)

```
## Finding
<root cause, 1–2 lines, plain words, up-front>

## Evidence
<table or 3–6 bullets — concrete numbers: QPM, error %, exception types, time window>

## Next step
<one concrete tool call OR mitigation suggestion>
```

Drop sections that don't apply. Never paste raw tool output.

## Layer discipline — pick the right tool

- **"slow", "p99", "latency"** → service graph only. Code path has NO latency.
- **"exception type", "where does X exception come from"** → code path only. Graph has only error %.
- **"what depends on X" → use `karmaiq-impact` if installed; do not investigate here.
- **"is the canary safe to promote"** → use `karmaiq-promotion-gate` if installed; do **not** call `regression_diff` from here.

## Hard rules

1. Never compute epochs from local clock — always `get_time_intervals` first.
2. Never type a service or API name into a graph tool without `search_catalog`.
3. Preserve route paths byte-for-byte. `([^/]+)` stays `([^/]+)` — never rewrite to `{id}`.
4. If a tool returns empty, run the empty-result checklist (widen time, verify domain, re-resolve, check list-vs-detail) before reporting no incident.
5. Amplification > 2× on any edge → flag it. One upstream request causing >2 downstream = cascading-load risk.

## Forbidden

- Mutating anything (this plugin is read-only)
- Calling `regression_diff` (that is the canary gate, not RCA)
- Dumping raw tool output without interpretation
- Asking the code-path layer for latency, or the graph layer for exception types
