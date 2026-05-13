---
description: Run karmaIQ regression_diff as a canary promotion gate. Returns one of four verdicts — STABLE, WATCH, REGRESSION, INSUFFICIENT_DATA — that pipelines and humans act on directly. Manual invocation only — must never auto-fire. Compares canary vs stable replicasets, or two services/APIs cross-entity.
disable-model-invocation: true
allowed-tools: mcp__karma-iq__regression_diff, mcp__karma-iq__get_time_intervals, mcp__karma-iq__get_system_overview
---

# Canary promotion gate via karmaIQ regression_diff

This skill is manual-only. Deliberate promotion decisions must never auto-fire — the user invoked this skill on purpose.

## Decide: subagent or inline

**Delegate to the `karmaiq-canary-gate` subagent when:**

- The user asked for the verdict of a specific service or API canary
- The user wants a pipeline-ready JSON output
- The diff requires correct window sizing (15min default, but user may need to override)

**Stay inline when:**

- The user is asking for an explanation of verdict semantics without running a diff
- The user is iterating on parameters (different time window, different pair)

## Verdict semantics — load-bearing, do NOT paraphrase

| Verdict | Pipeline action | Driver |
|---|---|---|
| **STABLE** | Promote | No deltas above MED thresholds |
| **WATCH** | Human review required | MED deltas only |
| **REGRESSION** | **Block promotion** | Any HIGH-severity delta |
| **INSUFFICIENT_DATA** | **Block promotion** | < 2 replicasets observed |

Severity is computed server-side:

- **HIGH**: latency Δ% > 50, error pp delta > 5, amplification Δ% > 50, any new-only error code
- **MED**: latency Δ% > 20, error pp delta > 1, appeared/disappeared topology, amplification Δ% > 20

## Inline workflow (when not delegating)

1. `get_system_overview(domain="<active>")` if not yet called this session. Required by the gate tool.
2. `get_time_intervals(duration_minutes=15)` for the standard canary window. Override only if user specified.
3. Read active domain from `${CLAUDE_PLUGIN_DATA}/../karmaiq-core/domain.txt`.
4. Call `regression_diff` with raw user-supplied names. **Do NOT pre-resolve via `search_catalog`** — the tool fuzzy-matches internally.

### Modes (one tool, three modes — pick by inputs)

| Inputs | Mode | Use case |
|---|---|---|
| `pair_a` (svc + api) + `pair_b` (svc + api) | `cross_interface` | Compare two specific APIs across services |
| `pair_a` (svc only) | `replicaset` | Canary vs stable RS of same service |
| `pair_a` (svc + api or api only) | `replicaset_filtered` | RS comparison filtered to one API |
| `pair_a` (svc only) + `pair_b` (different svc only) | **BLOCKED** | Nexus does not implement whole-service cross-diff |

## Output template (mandatory)

```
**Verdict**: <STABLE / WATCH / REGRESSION / INSUFFICIENT_DATA>
**Mode**: <cross_interface / replicaset / replicaset_filtered>

<summary line — what was compared and over what window>

### Top drivers
| metric | side A | side B | Δ | severity |
|---|---|---|---|---|

### Recommendation
<one of:>
- STABLE → "Safe to promote."
- WATCH → "Human review required. MED deltas: <list>. Proceed with caution."
- REGRESSION → "Block promotion. Top driver: <name>. Investigate via /karmaiq-firefighter:fire <target>."
- INSUFFICIENT_DATA → "Only one replicaset observed in window. Cannot validate. Extend window or wait for more data."

### Pipeline JSON
```json
{"verdict":"...","mode":"...","drivers":[...],"deltas":[...],"rs_meta":{...}}
```

## Hard rules

1. **Never paraphrase the verdict to sound better than it is.** REGRESSION stays REGRESSION; WATCH stays WATCH.
2. **Do not pre-resolve names** — pass raw user input to `regression_diff`.
3. **Do not use this skill to investigate a known regression.** Wrong tool. Route the user to `karmaiq-firefighter` for RCA.
4. **The user is read-only on prod via karmaIQ.** This plugin recommends actions; never mutates.

## Forbidden

- Auto-firing this skill (it's `disable-model-invocation: true` — Claude should never load this without explicit slash invocation)
- Calling `regression_diff` with both `pair_a_service` (no api) AND `pair_b_service` (different svc, no api) — that mode is blocked server-side
- Computing severity thresholds yourself — `regression_diff` returns them; respect what comes back
