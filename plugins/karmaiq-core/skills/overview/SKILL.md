---
description: Snapshot of the active karmaIQ domain — total nodes, edges, interfaces, top services by QPM, top error-rate interfaces. Manual command for quick orientation.
disable-model-invocation: true
allowed-tools: mcp__karma-iq__get_system_overview
---

# Overview of the active karmaIQ domain

Quick health snapshot.

## Steps

1. Read the active domain from `${CLAUDE_PLUGIN_DATA}/domain.txt`. If absent or empty, tell the user *"No karmaIQ domain set — run `/karmaiq-core:setup` first."* and stop.
2. Call `mcp__karma-iq__get_system_overview(domain="<active>", top_k=20)`.
3. Render the result:

```
## Domain: <name>

**Scale**: <n> nodes · <m> edges · <k> interfaces

**Top services by QPM**
| service | QPM | error % |
|---|---|---|
<top 5>

**Top error-rate interfaces**
| interface | error % | QPM |
|---|---|---|
<top 5>
```

4. End with a routing suggestion based on what stands out:
   - If any top interface has error % > 5: *"For incident response on these, install `karmaiq-firefighter` and run `/karmaiq-firefighter:fire <interface-id>`."*
   - Otherwise: *"Mesh looks healthy. For structural review use `karmaiq-architect`; for change-safety checks use `karmaiq-impact`."*
