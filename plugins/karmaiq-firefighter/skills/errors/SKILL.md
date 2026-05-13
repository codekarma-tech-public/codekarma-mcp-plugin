---
description: List top error-rate HTTP interfaces in the active karmaIQ domain right now. One-shot triage view — useful at the start of an incident when you don't know where the problem is.
disable-model-invocation: true
allowed-tools: mcp__karma-iq__rank_interfaces, mcp__karma-iq__get_time_intervals, mcp__karma-iq__get_system_overview
---

# Top errors right now

One-shot triage: which interfaces are erroring most over the last hour.

## Workflow

1. Read the active domain from `${CLAUDE_PLUGIN_DATA}/../karmaiq-core/domain.txt`. If absent, stop and instruct the user to run `/karmaiq-core:setup`.
2. Call `get_system_overview(domain="<active>")` if not yet called this session (cheap, primes context).
3. Call `get_time_intervals(duration_minutes=60, num_windows=1)`.
4. Call `rank_interfaces(metric="errors", node_type_filter="http", top_k=10, epochStartTime=..., epochEndTime=..., domain="<active>")`.
5. Render top 10 in a table with: interface (full `node_id`), error %, QPM, fan_in.
6. End with: *"Run `/karmaiq-firefighter:fire <interface-id>` to investigate any of these."*

## Path preservation

Echo `node_id` and route paths byte-for-byte — `([^/]+)` stays as-is.
