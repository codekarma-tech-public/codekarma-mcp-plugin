---
description: Find methods Nexus has marked as inactive or blacklisted in a karmaIQ service — code that production never calls. Manual slash invocation.
disable-model-invocation: true
argument-hint: "<service-name>"
allowed-tools: mcp__karma-iq__analyze_codebase_methods, mcp__karma-iq__search_catalog
---

# Dead code in `$ARGUMENTS`

## Workflow

1. Read active domain from `${CLAUDE_PLUGIN_DATA}/../karmaiq-core/domain.txt`. If unset → stop.
2. Optionally `search_catalog(catalog="graph", query="$ARGUMENTS", type_filter="system_unit")` to confirm the service name resolves.
3. Call `analyze_codebase_methods(service_name="$ARGUMENTS", strategy="dead_code", top_k=20, domain="<active>")`.
4. Render the result as:

```
## Dead methods in <service>

**Total**: <X blacklisted / Y inactive>

| method (Class.method) | status | last seen |
|---|---|---|
<top 20>
```

5. **Important**: if the response indicates no method-level instrumentation for this service, say so explicitly — do **not** claim "no dead code". The tool's silence ≠ no dead code.
6. End with: *"Before removing any of these, run `/karmaiq-impact:method $ARGUMENTS <method>` to confirm no production callers."*
