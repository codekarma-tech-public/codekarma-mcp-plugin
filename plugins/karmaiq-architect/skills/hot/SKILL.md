---
description: Top CPU-consuming methods in a karmaIQ service. Manual slash invocation.
disable-model-invocation: true
argument-hint: "<service-name>"
allowed-tools: mcp__karma-iq__analyze_codebase_methods
---

# Hot methods in `$ARGUMENTS`

## Workflow

1. Read active domain from `${CLAUDE_PLUGIN_DATA}/../karmaiq-core/domain.txt`. If unset → stop.
2. Call `analyze_codebase_methods(service_name="$ARGUMENTS", strategy="hot", top_k=20, cpu_threshold=1.0, domain="<active>")`.
3. Render as:

```
## Hot methods in <service>

| method (Class.method) | CPU % | calls/min | category |
|---|---|---|---|
<top 20, ordered by CPU>
```

4. End with: *"For deeper analysis of any flow these methods participate in, look up the method's flow via `mcp__karma-iq__search_catalog(catalog="method", query="<method>", service_name="$ARGUMENTS")` and run `mcp__karma-iq__analyze_flow` on the returned flow_id."*

5. If the service is not instrumented at method level, say so explicitly — do **not** report "no hot methods".
