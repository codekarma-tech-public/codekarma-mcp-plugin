# karmaiq-promotion-gate

> Canary deploy verdict, grounded in production deltas. `regression_diff` returns one of four states; pipelines and humans act on them.

## Why this plugin

Canary promotion gates fail when they're based on synthetic checks (latency p99 on a synthetic probe) instead of real traffic deltas. karmaIQ's `regression_diff` compares the canary replicaset (or one service) against a stable baseline over a window and emits a load-bearing verdict:

- **STABLE** — safe to promote
- **WATCH** — only MED deltas; human review required before promoting
- **REGRESSION** — HIGH-severity deltas; **block promotion**
- **INSUFFICIENT_DATA** — Nexus observed < 2 replicasets in the window; **block promotion** (cannot validate)

Verdicts are direct signals for CI/CD pipelines and humans. **Never paraphrase them to sound better than they are.**

## Install

Requires `karmaiq-core` for the MCP connection. Install both:

```
/plugin install karmaiq-core@karmaiq
/plugin install karmaiq-promotion-gate@karmaiq
```

## How it works

- **`gating-canary-promotion` skill** is `disable-model-invocation: true` — only the user can invoke it. Claude will not auto-fire this skill on a session where it overhears "canary"; you must explicitly invoke it. Deliberate promotion decisions must not be automated by accident.
- **`karmaiq-canary-gate` subagent** runs the diff with the right window and returns verdict + drivers as both a markdown summary and a JSON block suitable for CI pipelines to parse.
- **Slash commands** for direct invocation.

## Commands

| Command | What |
|---|---|
| `/karmaiq-promotion-gate:canary <service>` | Run the gate on the canary replicaset of `<service>` over the last 15 minutes |
| `/karmaiq-promotion-gate:diff <service-a> <service-b>` | Cross-entity diff between two services or APIs |

## Verdict semantics — load-bearing

| Verdict | Trigger | Pipeline action |
|---|---|---|
| **STABLE** | No deltas above MED thresholds | Promote |
| **WATCH** | MED deltas only (latency Δ% 20–50, error pp delta 1–5, amplification Δ% 20–50, appeared/disappeared topology) | Human review before promote |
| **REGRESSION** | Any HIGH-severity delta (latency Δ% > 50, error pp delta > 5, amplification Δ% > 50, any new-only error code) | **Block promotion** |
| **INSUFFICIENT_DATA** | Nexus observed < 2 replicasets in window | **Block promotion** (can't validate) |

Severity thresholds live inside the karmaIQ server — `regression_diff` returns the verdict; this plugin never recomputes thresholds.

## Pass raw user input

**Do not** pre-resolve service or API names via `search_catalog` before calling `regression_diff`. The tool fuzzy-matches internally and refuses on ambiguity — pre-resolving wastes the in-tool match and risks passing a slightly-wrong canonical ID. The subagent's system prompt enforces this.

## Use against the right question

`regression_diff` is a **promotion gate**, not an investigation tool. If a regression is already known and you want to find the root cause, use `karmaiq-firefighter` (`/karmaiq-firefighter:fire`) — not this plugin.

## Example: canary gate

> **User**: `/karmaiq-promotion-gate:canary winterfell`
>
> *(subagent runs `regression_diff` with 15min window on `winterfell`)*
>
> **Result**:
>
> ```
> Verdict: REGRESSION
> Mode: replicaset
> Top driver: latency Δ% = +73 (p99 on POST /api/v2/order)
>
> | metric | side A (canary) | side B (stable) | Δ |
> |---|---|---|---|
> | p99 latency | 312ms | 180ms | +73% |
> | error rate | 4.1% | 0.6% | +3.5pp |
>
> Recommendation: Block promotion. Use `/karmaiq-firefighter:fire winterfell` to investigate.
> ```
>
> ```json
> {"verdict":"REGRESSION","mode":"replicaset","drivers":[{"metric":"p99","delta_pct":73,"interface":"POST::/api/v2/order"}],"rs_meta":{"canary":"v1.2.3","stable":"v1.2.2"}}
> ```

## CI/CD integration

The JSON block in the subagent's return is stable-schema. Pipelines can parse:

```bash
VERDICT=$(claude /karmaiq-promotion-gate:canary winterfell --print --json | jq -r '.verdict')
case "$VERDICT" in
  STABLE) echo "Promote"; exit 0 ;;
  WATCH) echo "Human review"; exit 1 ;;
  REGRESSION|INSUFFICIENT_DATA) echo "Block"; exit 2 ;;
esac
```

(See Claude Code CLI docs for `--print` / `--json` flag availability.)

## Safety

- Subagent has **read-only** karmaIQ tools.
- Skill is `disable-model-invocation: true` — Claude cannot auto-promote a canary by mistake.
