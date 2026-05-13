---
description: Walk upstream root-cause candidates for a specific karmaIQ interface ID or service. Manual slash invocation when the user already has a resolved interface_id or knows the target service. Ranks predecessors by error rate over the active time window.
disable-model-invocation: true
argument-hint: "<interface-id-or-service-name>"
allowed-tools: mcp__karma-iq__root_cause_candidates, mcp__karma-iq__get_time_intervals, mcp__karma-iq__search_catalog
---

# Root-cause walk on $ARGUMENTS

Walk upstream from `$ARGUMENTS`, ranking predecessors by error rate.

## Workflow

1. If `$ARGUMENTS` does not contain `::` (so it's likely a service or API name, not a full `node_id`), call `search_catalog(catalog="graph", query="$ARGUMENTS")` to resolve. Take the top match if unambiguous; otherwise list options and ask the user.
2. Call `get_time_intervals(duration_minutes=720, num_windows=1)`.
3. Read the active domain from `${CLAUDE_PLUGIN_DATA}/../karmaiq-core/domain.txt`.
4. Call `root_cause_candidates(node_id="<resolved>", metric="errors", depth=3, top_k=10, epochStartTime=..., epochEndTime=..., domain="<active>")`.
5. Render the top 5 candidates with error % and QPM. End with:
   - One concrete next call (e.g. `get_api_deep_dive` on the worst candidate)
   - Or routing to `karmaiq-firefighter:fire <candidate>` for a deeper end-to-end run

## Path preservation

If `$ARGUMENTS` contains a route path, preserve it byte-for-byte — never rewrite `([^/]+)` to `{id}`.
