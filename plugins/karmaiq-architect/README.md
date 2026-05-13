# karmaiq-architect

> Find structural risk before it bites. Cycles, single points of failure, dead code, hot methods, fan-in/out — surfaced from real production traffic, not static analysis.

## Why this plugin

Most architecture reviews work from diagrams that go stale or static analyzers that don't know which services actually carry traffic. karmaIQ surfaces structural risk **weighted by production behavior** — a circular dependency only matters if traffic flows through it; dead code is only dead if production never calls it.

## Install

Requires `karmaiq-core` for the MCP connection. Install both:

```
/plugin install karmaiq-core@karmaiq
/plugin install karmaiq-architect@karmaiq
```

## How it works

- **`reviewing-system-architecture` skill** auto-loads when you mention architecture review, structural risk, cycles, SPOFs, dead code, hot methods, or fan analysis.
- **`karmaiq-architect` subagent** runs a full-domain audit (SPOF → cycles → orphans → fan_in → top dead-code services) and returns a ranked risk table.
- **Slash commands** for single-shot analyses.

## Commands

| Command | What |
|---|---|
| `/karmaiq-architect:cycles` | Find circular dependencies in the active domain |
| `/karmaiq-architect:spof` | List single points of failure (services with many dependents) |
| `/karmaiq-architect:deadcode <service>` | Methods Nexus has marked blacklisted/inactive in this service |
| `/karmaiq-architect:hot <service>` | Top CPU-consuming methods in this service |
| `/karmaiq-architect:fan [in\|out]` | Most-depended-on or most-fanning-out interfaces |

## Example: full audit

Ask: *"Run a karmaIQ architecture audit on the active domain."*

The skill delegates to `karmaiq-architect` subagent. It walks:

1. `analyze_architecture(spof)` → top single points of failure
2. `analyze_architecture(cycles)` → circular dependency chains
3. `analyze_architecture(orphans)` → services with no traffic
4. `rank_interfaces(fan_in)` → most-depended-on
5. `analyze_codebase_methods(dead_code)` → top services with dead methods

Returns one ranked risk table with severity, evidence, and recommended next action.

## Safety

- Subagent has **read-only** karmaIQ tools. Cannot mutate anything.
- All slash commands work on the active domain only — set with `/karmaiq-core:setup`.

## Troubleshooting

- **"No data" on a service** → confirm the service name via `/karmaiq-core:overview` to see canonical names in the active domain.
- **`/deadcode` returns empty** → service may not be instrumented at method level. Most karmaIQ method-layer tools require Nexus instrumentation; not all services qualify.
