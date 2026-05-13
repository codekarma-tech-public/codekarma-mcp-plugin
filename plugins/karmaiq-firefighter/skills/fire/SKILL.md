---
description: Run the karmaiq-firefighter incident workflow on a specific API or service name. Direct slash entry into the SRE subagent — for when you know the target and want a focused investigation.
disable-model-invocation: true
argument-hint: "<api-path-or-service-name>"
allowed-tools: mcp__karma-iq__*
---

# Fire karmaIQ firefighter on $ARGUMENTS

The user wants an end-to-end karmaIQ incident diagnosis on `$ARGUMENTS`.

## Action

Invoke the `karmaiq-firefighter` subagent via the Task tool. Pass this prompt verbatim:

> Run the full incident workflow on `$ARGUMENTS`. Resolve the name via `search_catalog(catalog="graph")`, find when the problem occurred (try `duration_minutes=720, num_windows=12` first to locate the spike), then `get_api_deep_dive`, `root_cause_candidates`, and `diagnose_code_path_errors` as needed. Return Finding / Evidence / Next-step.

When the subagent returns, present its summary **verbatim** to the user. Do not re-investigate or paraphrase. Add one line of routing at the end suggesting `karmaiq-impact` if a mitigation involves changing a service.
