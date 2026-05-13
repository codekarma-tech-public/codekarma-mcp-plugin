---
description: Run impact analysis on a single method. Manual slash invocation when the user knows the service and method name. Returns ranked callers with QPM and amplification flags.
disable-model-invocation: true
argument-hint: "<service-name> <Class.method-or-method-name>"
allowed-tools: mcp__karma-iq__analyze_code_path_impact, mcp__karma-iq__search_catalog, mcp__karma-iq__explore_code_path
---

# Impact analysis on method `$ARGUMENTS`

The user wants the blast radius of changing the method named in `$ARGUMENTS`.

## Parse arguments

`$ARGUMENTS` should be `<service-name> <Class.method-or-method-name>`. If only one token is supplied, ask the user for the missing piece before continuing.

## Workflow

1. Read active domain from `${CLAUDE_PLUGIN_DATA}/../karmaiq-core/domain.txt`. If unset → stop, instruct `/karmaiq-core:setup`.
2. `search_catalog(catalog="method", query="<method-token>", service_name="<service>")` to confirm the method resolves and grab the `method_hash` + candidate flow IDs.
3. `analyze_code_path_impact(service_name="<service>", query="<method-token>", include_flows=true)`.
4. If callers in the result are sparse (≤3), also run `explore_code_path(service_name=..., query=..., direction="callers", depth=3)` to confirm there's nothing missed.
5. Render:

```
## Method: <Class.method> in <service>

**Direct callers** (in this service): <count>
**Transitive callers** (cross-service): <count>
**Top callers by QPM**

| caller | QPM | amplification |
|---|---|---|

**Affected flows** (top 5): <list>

**Risk**: LOW / MED / HIGH (per analyzing-change-impact rubric)
```

6. End with one concrete next step (e.g. "Add a deprecation log to the top caller before removing"; "Safe to proceed — all callers in same module"; etc.).

## Preserve names verbatim

Class and method names are exact-match keys. Never reformat. If the user passed `payment_processor.charge`, do not convert to `PaymentProcessor.charge` — re-resolve via `search_catalog(catalog="method")` and use what the catalog returns.
