---
description: Surface architectural risk across the karmaIQ service mesh. Loads when the user mentions architecture review, structural risk, technical debt audit, pre-launch readiness, single points of failure (SPOF), circular dependencies, cycles, orphan services, dead code, hot CPU methods, or fan-in/fan-out analysis. Delegates full-domain audits to the karmaiq-architect subagent.
allowed-tools: mcp__karma-iq__*
---

# Reviewing system architecture with karmaIQ

The user wants to surface structural risk in the service mesh. This is deliberate work, not incident response — favor thoroughness over speed.

## Decide: subagent or inline

**Delegate to the `karmaiq-architect` subagent when:**

- The user asked for a full audit / readiness review / tech-debt sweep
- Multiple analysis types are in scope (SPOF + cycles + orphans + fan)
- The output will be a ranked risk register, not a single answer

The subagent runs all five analyses in one isolated pass and returns a consolidated risk table.

**Stay inline when:**

- The user asked for a single analysis type ("are there any cycles?", "find SPOFs only")
- The user is iterating ("now show me fan-in", "now dead code in payments-service")
- The slash command path is simpler

## Inline workflow (single-analysis)

| User asked for… | Tool |
|---|---|
| Circular dependencies | `analyze_architecture(analysis_type="cycles", max_length=10, max_results=20)` |
| Single points of failure | `analyze_architecture(analysis_type="spof", min_dependents=3)` |
| Orphan services | `analyze_architecture(analysis_type="orphans", traffic_threshold=0)` |
| Most-depended-on interfaces | `analyze_architecture(analysis_type="fan_in", top_k=20)` or `rank_interfaces(metric="fan_in")` |
| Highest-fanout services | `analyze_architecture(analysis_type="fan_out")` |
| Dead code in a service | `analyze_codebase_methods(service_name=..., strategy="dead_code")` |
| Hot CPU methods in a service | `analyze_codebase_methods(service_name=..., strategy="hot", cpu_threshold=1.0)` |

Read active domain from `${CLAUDE_PLUGIN_DATA}/../karmaiq-core/domain.txt`. Pass `domain=...` on every call.

## Output template

```
## Finding
<1–2 lines summarizing the risk found — or "no risk surfaced">

## Evidence
<table or 3–6 bullets with concrete numbers — cycle lengths, dependent counts, dead-method counts, CPU %>

## Next step
<one concrete action: fix the top SPOF, refactor the largest cycle, remove top N dead methods, etc.>
```

For zero-finding cases, still produce the Finding ("No cycles ≤ length 10 in active domain") with Evidence (the query parameters).

## Risk prioritization

When multiple findings exist, rank by:

1. **HIGH**: SPOFs with > 10 dependents, cycles with traffic flowing through them (any edge QPM > 0), services with > 50% dead methods by count
2. **MED**: SPOFs with 3–10 dependents, cycles with no traffic flow, hot methods consuming > 5% CPU
3. **LOW**: Orphan services with zero traffic, small fan-in clusters

## Hard rules

1. **`get_system_overview` first** if not already called this session.
2. **Preserve service names and `node_id`s byte-for-byte.** Architecture analyses return canonical IDs; echo them as-is.
3. **Read active domain from `${CLAUDE_PLUGIN_DATA}/../karmaiq-core/domain.txt`.** If unset, stop and tell the user to run `/karmaiq-core:setup`.
4. **Distinguish "no instrumentation" from "no risk".** `analyze_codebase_methods` returns empty for services without method-level instrumentation — say so, don't claim the service has no dead code.

## Forbidden

- Recommending mutations (read-only plugin)
- Comparing snapshots across time — that's `regression_diff` (canary gate, not architecture)
- Conflating list-vs-detail endpoint shapes when reporting fan-in (`/api/foo/?` and `/api/foo/([^/]+)/?` are distinct)
- Dumping raw `analyze_architecture` output without ranking / interpretation
