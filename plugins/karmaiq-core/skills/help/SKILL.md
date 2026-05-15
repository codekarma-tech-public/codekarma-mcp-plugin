---
description: Discoverability guide for karmaIQ. Lists installed plugins, every karmaIQ slash command grouped by plugin, common workflows, and where to read more. Loads when the user asks "what can karmaIQ do", "karmaiq help", "list karmaiq commands", "how do I use karmaiq", or invokes /karmaiq-core:help directly.
allowed-tools: Bash
---

# karmaIQ — what's here

Print this overview verbatim, then offer to drill into any section.

## Plugins in this marketplace

| Plugin | Purpose | Install |
|---|---|---|
| `karmaiq-core` | MCP wiring + domain picker + mesh exploration (foundation) | `/plugin install karmaiq-core@karmaiq` |
| `karmaiq-firefighter` | Autonomous SRE for production incident RCA | `/plugin install karmaiq-firefighter@karmaiq` |
| `karmaiq-impact` | Pre-change blast-radius analysis with pre-commit warning | `/plugin install karmaiq-impact@karmaiq` |
| `karmaiq-architect` | Structural review — cycles, SPOFs, dead code, hot methods | `/plugin install karmaiq-architect@karmaiq` |
| `karmaiq-promotion-gate` | Canary regression verdict — STABLE / WATCH / REGRESSION | `/plugin install karmaiq-promotion-gate@karmaiq` |

## All karmaIQ slash commands

### karmaiq-core
- `/karmaiq-core:setup` — pick active CodeKarma domain (one-time, then cached)
- `/karmaiq-core:overview` — snapshot active domain (top services, top errors)
- `/karmaiq-core:domain [name]` — show or switch active domain
- `/karmaiq-core:help` — this command

### karmaiq-firefighter
- `/karmaiq-firefighter:fire <api-or-service>` — end-to-end incident RCA via the firefighter subagent
- `/karmaiq-firefighter:rca <interface-id-or-service>` — upstream root-cause walk ranked by error rate
- `/karmaiq-firefighter:errors` — top error-rate HTTP interfaces right now

### karmaiq-impact
- `/karmaiq-impact:method <service> <method>` — blast radius of changing one method
- `/karmaiq-impact:service <service>` — what breaks if this service goes down
- `/karmaiq-impact:path <from> <to>` — all paths between two services

### karmaiq-architect
- `/karmaiq-architect:cycles` — circular dependencies in the active domain
- `/karmaiq-architect:spof` — single points of failure
- `/karmaiq-architect:deadcode <service>` — Nexus-marked inactive methods
- `/karmaiq-architect:hot <service>` — top CPU-consuming methods
- `/karmaiq-architect:fan [in|out]` — most-depended-on / most-fanning-out interfaces

### karmaiq-promotion-gate
- `/karmaiq-promotion-gate:canary <service>` — canary regression verdict (15min window)
- `/karmaiq-promotion-gate:diff <a> <b>` — cross-entity regression diff

## Most common workflows

| Scenario | What to type |
|---|---|
| First install on a new machine | `/karmaiq-core:setup` (then install other plugins per persona) |
| Production API is failing | Natural-language: *"checkout API is returning 5xx, what's going on?"* — firefighter subagent runs end-to-end |
| About to refactor a method | Natural-language in a code file: *"is calculateLegacyTax safe to delete?"* — impact skill loads |
| Quarterly architecture audit | Natural-language: *"run a karmaIQ architecture audit"* — architect subagent runs full sweep |
| Canary deploy decision | `/karmaiq-promotion-gate:canary <service>` — returns STABLE / WATCH / REGRESSION / INSUFFICIENT_DATA |

## Read more

- [README.md](../../../README.md) — marketplace landing
- [EXAMPLES.md](../../../EXAMPLES.md) — full user-journey walkthrough with copy-pasteable prompts and expected outputs
- Each plugin's `README.md` for plugin-specific details
- `CHANGELOG.md` — what's new
- Set `KARMAIQ_MCP_URL` for BYOC (bring-your-own-cloud) instances

## Tips for butter-smooth UX

1. Mention API paths byte-for-byte — the pre-warm hook resolves them automatically.
2. Don't rewrite `([^/]+)` to `{id}` — karmaIQ does exact match on regex form.
3. Trust subagent delegation — firefighter / impact-analyzer / architect / canary-gate return one focused summary instead of flooding chat.
4. `disable-model-invocation: true` skills (`setup`, `canary`, `gating-canary-promotion`) only fire when you type them — safe by design.
5. Opt out of hooks if they get noisy: `KARMAIQ_NO_PREWARM=1`, `KARMAIQ_NO_PRECOMMIT_IMPACT=1`.
