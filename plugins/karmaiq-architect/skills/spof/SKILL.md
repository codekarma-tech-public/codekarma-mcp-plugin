---
description: List single points of failure in the active karmaIQ domain — services with many downstream dependents whose failure would cascade. Manual slash invocation.
disable-model-invocation: true
allowed-tools: mcp__karma-iq__analyze_architecture
---

# Single points of failure in the active domain

## Workflow

1. Read active domain from `${CLAUDE_PLUGIN_DATA}/../karmaiq-core/domain.txt`. If unset → stop.
2. Call `analyze_architecture(analysis_type="spof", min_dependents=3, top_k=20, domain="<active>")`.
3. Render as a table:

```
| service | dependents | total QPM at risk | criticality |
|---|---|---|---|
```

4. Tag criticality:
   - **HIGH** if dependents > 10 OR total QPM at risk > 1000
   - **MED** if dependents 5–10
   - **LOW** if dependents 3–4
5. End with: *"To see the full blast radius of any of these, run `/karmaiq-impact:service <name>`."*
