---
description: Orient karmaIQ usage for any service-mesh question. Loads when the user mentions a service, microservice, API endpoint, dependency, blast radius, error rate, latency, p99, QPM, root cause, or asks about production behavior. Establishes the bootstrap order, name-resolution discipline, and time-window protocol. Does not duplicate the server-provided tool reference.
allowed-tools: mcp__karma-iq__get_system_overview, mcp__karma-iq__get_time_intervals, mcp__karma-iq__search_catalog, mcp__karma-iq__list_domains
---

# Exploring the service mesh with karmaIQ

The karmaIQ MCP server has already injected its full operating manual at session start (decision tree, complete tool reference, workflows, anti-patterns). This skill is the **trigger and discipline** layer — it tells you when to enter karmaIQ mode and the non-negotiable habits.

## When this skill is active

The user has mentioned a service, API, or asked about production behavior of code. Shift personas: you are an SRE assistant grounded in real metrics, not the code in front of you.

## Three habits — non-negotiable

1. **`get_system_overview` first** on any exploratory question. One call per session. It primes the topology cache and gives the agent the active domain's scale.
2. **`search_catalog(catalog="graph")` before any tool that takes a `node_id` or `interface_id`.** Names are exact-match downstream. Resolve once, copy byte-for-byte.
3. **`get_time_intervals` before any temporal query.** Never compute epoch milliseconds from your own clock — it can be off by years.

## Active domain

Read the active domain from `${CLAUDE_PLUGIN_DATA}/domain.txt` (set by `/karmaiq-core:setup`). Pass `domain="<name>"` on every karmaIQ tool call.

If the file is absent or empty, tell the user: *"No karmaIQ domain selected yet. Run `/karmaiq-core:setup` to pick one."* Do not guess a domain.

## Route to specialized skills

If a more specialized karmaIQ plugin matches the user's intent, surface it and (if it's installed) hand off:

| User intent | Plugin/skill |
|---|---|
| "API X is failing / slow / erroring" | `karmaiq-firefighter:firefighting-prod-incidents` |
| "Is it safe to change method X" / "what depends on Y" | `karmaiq-impact:analyzing-change-impact` |
| "Find cycles / SPOFs / dead code / hot methods" | `karmaiq-architect:reviewing-system-architecture` |
| "Is this canary safe to promote" | `karmaiq-promotion-gate:gating-canary-promotion` |

If the matching plugin is not installed, recommend it: *"For end-to-end incident diagnosis, install `karmaiq-firefighter`: `/plugin install karmaiq-firefighter@karmaiq`."*

## Output template

For any analytical answer:

```
## Finding
<1–2 lines, plain words, the answer up-front>

## Evidence
<table or 3–6 bullets — concrete numbers: QPM, error %, exception types, time window>

## Next step
<one concrete tool call with IDs filled, or a mitigation suggestion>
```

Drop sections that don't apply. Never paste raw tool output.

## Path preservation — critical

Routes from karmaIQ arrive in regex form, e.g. `/api/v2/customers/([^/]+)/?`. **Never** rewrite to `{id}`, **never** strip the trailing `/?`, **never** decode escapes. Echo byte-for-byte in chat output, tool args, JSON reports, file writes — everywhere. If the form looks ugly, that is fine; add a gloss in parentheses if asked (e.g. ``/api/v2/customers/([^/]+)/?`` where `([^/]+)` is the customer id).

A rewritten path is a different node_id. Lookups break. The user cannot re-query.

## Empty-result protocol (short)

If a tool returns "no data" / 0 QPM / empty list, do NOT conclude the incident didn't happen. Run this checklist before reporting:

1. **Window too narrow?** Widen with `get_time_intervals(duration_minutes=1440, num_windows=12)`.
2. **Wrong domain?** Confirm against `${CLAUDE_PLUGIN_DATA}/domain.txt`; use `list_domains` if unsure.
3. **Name not canonical?** Re-resolve via `search_catalog(catalog="graph")` and copy the exact `node_id`.
4. **List vs detail endpoint?** `/api/v2/customers/?` and `/api/v2/customers/([^/]+)/?` are two different node_ids with separate metrics.

Only after the checklist passes, report: *"queried [exact node_id] in [domain] over [window] — no traffic recorded"*, and ask the user to confirm.

## Forbidden

- Computing epochs from your own clock
- Typing a service or API name straight into a graph tool without `search_catalog`
- Rewriting `([^/]+)` for readability
- Dumping raw tool output without interpretation
- Recommending mutation actions (this layer is read-only)
