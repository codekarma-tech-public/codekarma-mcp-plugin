---
description: List most-depended-on (fan_in) or most-fanning-out (fan_out) interfaces in the active karmaIQ domain. Manual slash invocation.
disable-model-invocation: true
argument-hint: "[in|out]"
allowed-tools: mcp__karma-iq__rank_interfaces, mcp__karma-iq__analyze_architecture
---

# Fan analysis on the active domain

## Parse arguments

- `$ARGUMENTS` empty or `in` → fan-in (most-depended-on)
- `$ARGUMENTS` is `out` → fan-out (services calling the most things)

## Workflow

1. Read active domain from `${CLAUDE_PLUGIN_DATA}/../karmaiq-core/domain.txt`. If unset → stop.
2. Call:
   - For fan-in: `rank_interfaces(metric="fan_in", top_k=20, node_type_filter="http", domain="<active>")`
   - For fan-out: `analyze_architecture(analysis_type="fan_out", top_k=20, domain="<active>")`
3. Render as a table with: interface/service, fan count, QPM.
4. End with:
   - For fan-in: *"These are the highest-blast-radius interfaces in the domain. Run `/karmaiq-impact:service <name>` to see what breaks if any of them go down."*
   - For fan-out: *"These services call the most downstream — they're candidates for amplification risk. Run `/karmaiq-firefighter:rca <service>` if any of them show elevated error rates."*

## Preserve identifiers verbatim

`node_id`s and route paths byte-for-byte.
