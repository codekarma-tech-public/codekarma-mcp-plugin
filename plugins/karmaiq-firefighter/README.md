# karmaiq-firefighter

> Autonomous SRE for production incident diagnosis. When you describe a failing API or service, this plugin runs the full karmaIQ root-cause workflow in an isolated subagent and returns a focused Finding / Evidence / Next-step summary.

## Why this plugin

A normal coding session has no context on which APIs are erroring in prod, which services are slow, or where exceptions originate. This plugin closes that gap end-to-end. You describe the symptom; karmaIQ resolves the right interface, the right time window, walks upstream root-cause candidates, and pulls method-level exception traces — all without flooding your main conversation with intermediate tool output.

## Install

Requires `karmaiq-core` for the MCP connection. Install both:

```
/plugin install karmaiq-core@karmaiq
/plugin install karmaiq-firefighter@karmaiq
```

## How it works

1. **Pre-warm hook** (`UserPromptSubmit`) — silently scans your message for API paths (`/api/v1/...`) and service-like names. If detected, it injects a hint to Claude to resolve them via `search_catalog` before any graph tool call. Saves a round-trip on first answer. Opt out with `KARMAIQ_NO_PREWARM=1`.
2. **`firefighting-prod-incidents` skill** — auto-loads when you mention API errors, latency, alerts, or "something is broken in prod". Decides whether to investigate inline or delegate to the subagent.
3. **`karmaiq-firefighter` subagent** — runs the W1 workflow (time window → resolve → API deep dive → upstream walk → exception trace) in isolated context. Returns a single Finding / Evidence / Next-step summary.

## Commands

| Command | What |
|---|---|
| `/karmaiq-firefighter:fire <api or service>` | Full incident workflow on a target. Delegates to the subagent. |
| `/karmaiq-firefighter:rca <interface-id-or-service>` | Walk upstream root-cause candidates ranked by error rate. |
| `/karmaiq-firefighter:errors` | List top error-rate HTTP interfaces right now. |

## Example session

> **User**: checkout API has been erroring last hour
>
> *(pre-warm hook detects "checkout API", hints Claude)*
>
> *(skill activates → delegates to firefighter subagent)*
>
> **Claude (relaying subagent output)**:
>
> ## Finding
> 90% 5xx error rate on `POST /api/v1/checkout` over the last 12 windows. Root cause is upstream `payments-service` returning `PaymentTimeoutException`.
>
> ## Evidence
> | window (last 60m) | error % | upstream returning errors |
> |---|---|---|
> | 0–5m | 92 | payments-service |
> | 5–10m | 88 | payments-service |
> | … | … | … |
>
> Method root: `PaymentClient.charge()` → `HttpTimeoutException` wrapped as `PaymentTimeoutException`.
>
> ## Next step
> Run `/karmaiq-impact:service payments-service` before mitigating — `karmaiq-impact` plugin shows what else depends on payments before you restart it.

## Safety

- Subagent has **read-only** karmaIQ tools. Cannot run Bash, edit files, or call non-karmaIQ MCP servers.
- Pre-warm hook is fail-silent and time-bounded (≤3s). It only **hints** — never makes API calls itself.

## Troubleshooting

- **Subagent doesn't activate** → check `/agents` lists `karmaiq-firefighter`. Run `/reload-plugins` if not.
- **Pre-warm not firing** → check `${KARMAIQ_NO_PREWARM}` is not set, and `/karmaiq-core:setup` has run.
- **"No domain set"** → run `/karmaiq-core:setup` first.
