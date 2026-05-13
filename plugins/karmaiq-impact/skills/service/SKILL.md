---
description: Service-level blast radius. What breaks if this service goes down. Manual slash invocation when the user wants to know the cost of a deploy, restart, or removal.
disable-model-invocation: true
argument-hint: "<service-name>"
allowed-tools: mcp__karma-iq__simulate_failure, mcp__karma-iq__search_catalog
---

# Service-level impact on `$ARGUMENTS`

The user wants the blast radius if service `$ARGUMENTS` were to fail.

## Workflow

1. Read active domain from `${CLAUDE_PLUGIN_DATA}/../karmaiq-core/domain.txt`. If unset → stop.
2. `search_catalog(catalog="graph", query="$ARGUMENTS")` → resolve to `node_id` (use top match if unambiguous; else list options and ask).
3. `simulate_failure(node_id="<resolved>", detail="summary", failure_type="down", depth=5)` — blast count by depth and type.
4. `simulate_failure(node_id="<resolved>", detail="full", failure_type="down", depth=5, top_k=20)` — ranked affected nodes by QPM lost.
5. Render:

```
## Service: <name>

**Blast summary**: <X services affected, Y interfaces, Z total QPM lost>

**Top affected interfaces by QPM lost**
| interface | QPM lost | depth |
|---|---|---|
<top 10>

**Amplification flags** (edges with > 2× amplification)
<list any, or "none"; one upstream request causing >2 downstream calls = cascading-load risk>
```

6. End with one concrete next step:
   - If LOW impact: "Safe to restart / scale down."
   - If MED/HIGH: "Coordinate with owners of <top affected services>. Consider draining or feature-flagging before action."

## Preserve names verbatim

The resolved `node_id` is the exact key. Echo it as-is; do not reformat.
