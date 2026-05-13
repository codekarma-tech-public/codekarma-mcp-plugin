---
description: Show all unique paths between two services in the karmaIQ graph. Manual slash invocation for understanding connectivity, finding hidden coupling, or planning a service rewire.
disable-model-invocation: true
argument-hint: "<from-service> <to-service>"
allowed-tools: mcp__karma-iq__find_path, mcp__karma-iq__search_catalog
---

# Paths from `$ARGUMENTS`

`$ARGUMENTS` should be `<from-service> <to-service>`. If only one token, ask for the missing one.

## Workflow

1. Read active domain from `${CLAUDE_PLUGIN_DATA}/../karmaiq-core/domain.txt`. If unset → stop.
2. `search_catalog(catalog="graph", query="<from>")` → `from_id`.
3. `search_catalog(catalog="graph", query="<to>")` → `to_id`.
4. `find_path(strategy="shortest", from_id="<resolved>", to_id="<resolved>", max_paths=5)`.
5. Also consider `find_path(strategy="critical", from_id=..., to_id=..., metric="latency")` if the user mentioned slowness, or `metric="qpm"` if they mentioned traffic.
6. Render each path as a numbered list with per-edge QPM and amplification.

End with: *"Want the critical path by latency? Re-run with `metric=latency`. Want the hottest-traffic path? `metric=qpm`."*
