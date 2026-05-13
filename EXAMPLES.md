# karmaIQ — User Journey & Examples

A guided tour for new installs. Copy-paste the prompts; watch the plugins compose.

This document assumes you've installed at least `karmaiq-core` plus one or more of the workflow plugins. See [README.md](README.md) for install instructions.

---

## 0. First-Boot Tour (~5 min)

Confirms everything works end-to-end before real work.

### Step 1 — pick domain

```
/karmaiq-core:setup
```

**What happens**: the `picking-active-domain` skill calls `list_domains`, shows your domains, asks which to set active. The choice is written to `${CLAUDE_PLUGIN_DATA}/domain.txt` and persists across sessions.

### Step 2 — snapshot

```
/karmaiq-core:overview
```

**What happens**: `get_system_overview` runs. You see node/edge counts, top services by QPM, top error-rate interfaces. Confirms the MCP wiring and domain work.

### Step 3 — natural language test

```
Show me the top errors in our mesh right now
```

**What happens**: the `exploring-service-mesh` skill auto-loads (matches "errors", "mesh"). Routes you to `karmaiq-firefighter:errors` if firefighter is installed; otherwise runs `rank_interfaces(metric="errors")` inline.

### Step 4 — pre-warm hook test

```
I'm investigating the /api/v2/checkout endpoint on the payments-service
```

**What happens**: the `UserPromptSubmit` hook (firefighter plugin) silently detects `/api/v2/checkout` and `payments-service`. It injects a pre-resolve hint to Claude before it reads your message. Claude resolves names correctly on first try, with no extra round-trip.

---

## Journey 1 — SRE On-Call: Incident Lands at 2 AM

### Scenario

PagerDuty fires. *"Elevated 5xx on checkout API."*

### Prompt 1 — describe the symptom

```
checkout API has been failing in production for the last hour, lots of 5xx errors. what's going on?
```

**What happens**:

1. `UserPromptSubmit` hook detects "checkout API" → injects a pre-resolve hint.
2. The `firefighting-prod-incidents` skill matches "failing", "5xx", "errors".
3. The skill delegates to the `karmaiq-firefighter` subagent via the Task tool.
4. The subagent runs the W1 workflow autonomously in an isolated context:
   - `get_time_intervals(duration_minutes=720, num_windows=12)` — find when
   - `search_catalog(catalog="graph", query="checkout")` — resolve `node_id`
   - `get_api_deep_dive(interface_id=..., epoch...)` — pinned RCA
   - `root_cause_candidates(...)` — upstream walk
   - `diagnose_code_path_errors(...)` — exception types
5. Returns one Finding / Evidence / Next step to the main chat.

**Expected output shape**:

```
## Finding
92% 5xx on POST /api/v1/checkout last 30m. Root cause: payments-service
returning PaymentTimeoutException (HttpTimeoutException wrapped).

## Evidence
| window | error % | upstream         |
| 0–5m   | 92      | payments-service |
| 5–10m  | 88      | payments-service |
| 10–15m | 70      | payments-service |

Method root: PaymentClient.charge() → HttpTimeoutException
Amplification flag: cart→payments edge at 3.2× (cascading)

## Next step
Run /karmaiq-impact:service payments-service before restarting to see
blast radius. Or /karmaiq-firefighter:rca payments-service for a deeper
upstream walk.
```

### Prompt 2 — drill into a specific upstream

```
/karmaiq-firefighter:rca payments-service
```

**What happens**: walks upstream from `payments-service`, ranks predecessors by error rate. Returns the top 5 with error % and QPM.

### Prompt 3 — confirm exception origin

```
where exactly is PaymentTimeoutException being thrown?
```

**What happens**: the `firefighting-prod-incidents` skill stays active. Routes to the code-path layer (not graph — exception type lives there). Runs `diagnose_code_path_errors(service_name="payments-service", query="PaymentTimeoutException")`. Returns the method emitting it plus the error chain.

### Prompt 4 — confirm safe to mitigate

```
is it safe to restart payments-service?
```

**What happens**: the skill recognizes the intent shift to impact analysis. Suggests `karmaiq-impact` plugin (or, if installed, hands off to `/karmaiq-impact:service payments-service`).

---

## Journey 2 — Dev: Pre-Refactor Safety Check

### Scenario

You're about to delete a method that "looks unused."

### Prompt 1 — opening question

```
I'm about to delete the calculateLegacyTax method in the billing-service.
is it actually unused in prod?
```

**What happens**:

1. You're in a `.py` / `.go` / `.ts` file → the `analyzing-change-impact` skill loads (path-scoped).
2. The skill recognizes "is it unused" intent → routes to the impact toolset.
3. Inline: `search_catalog(catalog="method", query="calculateLegacyTax", service_name="billing-service")`, then `analyze_code_path_impact(...)` and `explore_code_path(direction="callers")`.
4. Returns a risk classification plus evidence.

**Expected output**:

```
## Finding
NOT safe to delete. calculateLegacyTax has 47 active callers in last 24h,
including 3 cross-service calls from invoicing-service.

## Evidence
| caller                              | QPM  | amplification |
| BillingController.computeInvoice    | 12.4 | 1.0×          |
| InvoicingClient.fetchLegacyRate     | 2.1  | 1.8×          |
| TaxRecalcJob.process                | 0.5  | 1.0×          |
...

Risk: MED (50–500 QPM)

## Next step
Add @deprecated annotation + log line, monitor for one week, then re-run
this check before deletion.
```

### Prompt 2 — make a code change, then commit

```
Refactor calculateLegacyTax to take a TaxContext parameter and update the callers.
```

Claude edits the code. Then:

```
commit this with message "refactor tax calc to use context"
```

**What happens**:

1. Claude runs `git add` + `git commit` via the Bash tool.
2. The `PreToolUse` hook on `Bash(git commit *)` fires.
3. `precommit-impact.sh` reads the staged diff, detects changed method names via signatures and hunk-context.
4. Injects `additionalContext` like:
   ```
   karmaIQ pre-commit: staged diff covers 4 code file(s) [billing/tax.py,
   billing/controller.py, invoicing/client.py, tests/test_tax.py] (+47/-12 lines).
   Methods/functions/classes touched: calculateLegacyTax, computeInvoice,
   fetchLegacyRate. Recommend running /karmaiq-impact:method <service> <method>
   on production-loaded targets before this commit lands.
   ```
5. Claude reads the hint, optionally invokes the `karmaiq-impact-analyzer` subagent for the listed methods, presents the summary, then proceeds with the commit. The hook is **warn-only** — it never blocks.

### Prompt 3 — service-level impact for a deploy

```
/karmaiq-impact:service payments-service
```

**What happens**: `simulate_failure` runs in summary + full mode. Returns the top affected interfaces, total QPM at risk, and amplification flags. Tells you whether it's safe to restart or scale down.

### Prompt 4 — paths between services

```
/karmaiq-impact:path gateway billing-service
```

**What happens**: `find_path(strategy="shortest")` between the two. Shows all unique paths with per-edge QPM. Useful for understanding hidden coupling.

---

## Journey 3 — Architect: Quarterly Structural Review

### Scenario

You own architecture. Once a quarter, you sweep the mesh for risk.

### Prompt 1 — full audit (the killer prompt)

```
Run a karmaIQ architecture audit on the active domain. I want the risk register.
```

**What happens**:

1. The `reviewing-system-architecture` skill auto-loads (matches "audit", "architecture", "risk register").
2. The skill delegates to the `karmaiq-architect` subagent.
3. The subagent runs an 8-step audit:
   - `get_system_overview`
   - `analyze_architecture(spof)`
   - `analyze_architecture(cycles)`
   - `analyze_architecture(orphans)`
   - `rank_interfaces(fan_in)`
   - `analyze_codebase_methods(dead_code)` on top 3 services
4. Returns a consolidated risk register with HIGH / MED / LOW classifications.

**Expected output shape**:

```
## karmaIQ architecture audit — chargebee-prod

### Risk register
| # | risk                          | type   | severity | evidence |
| 1 | auth-service (12 dependents)  | SPOF   | HIGH     | 12 services depend, 4.2k QPM at risk |
| 2 | invoicing↔billing↔tax cycle   | Cycle  | HIGH     | 800 QPM flowing through 3-hop loop |
| 3 | legacy-reports (0 traffic)    | Orphan | LOW      | zero QPM in 24h |
...

### Top findings (detail)
**1. auth-service SPOF (HIGH)**
- 12 services depend, 4.2k QPM at risk if it goes down
- Next step: /karmaiq-impact:service auth-service for full blast radius

**2. invoicing → billing → tax → invoicing cycle (HIGH)**
- 800 QPM flowing through the loop
- Amplification on tax→invoicing edge: 2.4×
- Next step: break the tax→invoicing back-edge

### Summary
- HIGH: 2 | MED: 5 | LOW: 7
```

### Prompt 2 — drill into one finding

```
/karmaiq-architect:cycles
```

**What happens**: a standalone cycles run. Lists circular deps up to length 10, prioritized by traffic flow.

### Prompt 3 — find candidates for removal

```
/karmaiq-architect:deadcode reporting-service
```

**What happens**: methods Nexus has blacklisted in `reporting-service`. Shows last-seen and status. **Explicitly tells you if the service isn't method-instrumented** — it does not silently report "no dead code".

### Prompt 4 — hotspots

```
/karmaiq-architect:hot payments-service
```

**What happens**: top CPU-consuming methods. Useful for tech-debt sprints.

### Prompt 5 — most-depended-on

```
/karmaiq-architect:fan in
```

**What happens**: top fan-in interfaces in the mesh. These are your highest-blast-radius surfaces.

---

## Journey 4 — CI/CD: Canary Promotion Decision

### Scenario

Canary deployed 15 min ago. Should we promote?

### Prompt 1 — the gate

```
/karmaiq-promotion-gate:canary winterfell
```

**What happens**:

1. The `gating-canary-promotion` skill activates (manual only — won't auto-fire).
2. The skill delegates to the `karmaiq-canary-gate` subagent.
3. The subagent: `get_system_overview` → `get_time_intervals(duration_minutes=15)` → `regression_diff(pair_a_service="winterfell", epoch..., domain=...)` (passes the raw name — no pre-resolve).
4. Returns the verdict, drivers, and pipeline JSON.

**Expected output** (REGRESSION case):

````
**Verdict**: REGRESSION
**Mode**: replicaset

Compared canary RS vs stable RS of winterfell over last 15min in domain `got`.

### Top drivers
| metric          | side A (canary) | side B (stable) | Δ      | severity |
| p99 latency     | 312ms           | 180ms           | +73%   | HIGH     |
| error rate      | 4.1%            | 0.6%            | +3.5pp | MED      |
| amp on payments | 3.1×            | 1.2×            | +158%  | HIGH     |

### Recommendation
Block promotion. Top driver: p99 latency on POST /api/v2/order. Investigate
root cause via /karmaiq-firefighter:fire winterfell before any further
promotion attempt.

### Pipeline JSON
```json
{"verdict":"REGRESSION","mode":"replicaset","drivers":[...],"deltas":[...]}
```
````

### Prompt 2 — cross-service compare

```
/karmaiq-promotion-gate:diff payments-v1 payments-v2
```

**What happens**: compares two services (or two APIs). Same verdict semantics. If both are service-only and different services, the skill refuses (server doesn't support whole-service cross-diff).

### Prompt 3 — investigate the regression found

```
/karmaiq-firefighter:fire winterfell
```

**What happens**: switches from gate plugin to firefighter plugin. Different tool for different job — gate scores deltas, firefighter traces causes.

---

## Journey 5 — Crossover Workflows

### Scenario A — Hot path tracing

```
What's the highest-latency path between gateway and the orders database?
```

**What happens**: the `exploring-service-mesh` skill loads. Calls `find_path(strategy="critical", from_id=..., to_id=..., metric="latency")`. Returns ranked paths with per-edge latency.

### Scenario B — Map endpoint to code

```
Which controller handles GET /api/v1/orders in the orders service?
```

**What happens**: inline `map_api(...)`. Returns the controller, method, and flow IDs. Then offers `explore_method_hierarchy` to see callers/callees.

### Scenario C — "What's actually slow"

```
Show me the slowest APIs in the active domain over the last hour
```

**What happens**: `rank_interfaces(metric="latency", top_k=10)`. Returns a table with p99 and QPM. Routes to `/karmaiq-firefighter:fire <interface>` for any that look bad.

### Scenario D — Find a service by partial name

```
We have something called "billing" or "invoice" — what services exist for that?
```

**What happens**: `search_catalog(catalog="graph", query="billing")` and `query="invoice"`. Returns matches with `node_id`s. You pick.

### Scenario E — Domain switch mid-session

```
/karmaiq-core:domain chargebee-stage
```

**What happens**: writes the new domain to `domain.txt`. All subsequent calls query the new domain.

---

## Pattern Cheat Sheet

| Pattern | What you type | Plugin/skill |
|---|---|---|
| "API X is failing/slow" | natural language describing symptom | firefighter (auto) |
| "Run incident on X" | `/karmaiq-firefighter:fire <api>` | firefighter (slash) |
| "Top errors right now" | `/karmaiq-firefighter:errors` | firefighter (slash) |
| "Is it safe to change X" | natural language in code file | impact (auto, path-scoped) |
| "Impact of changing method X" | `/karmaiq-impact:method <svc> <method>` | impact (slash) |
| "What breaks if X dies" | `/karmaiq-impact:service <svc>` | impact (slash) |
| "Architecture audit" | natural language | architect (auto + subagent) |
| "Find cycles/SPOFs/dead code" | `/karmaiq-architect:cycles \| spof \| deadcode` | architect (slash) |
| "Can we promote this canary" | `/karmaiq-promotion-gate:canary <svc>` | promotion-gate (manual) |
| "Pick domain" | `/karmaiq-core:setup` | core (manual) |
| "What domain am I on" | `/karmaiq-core:domain` | core (manual) |

---

## Tips for butter-smooth UX

1. **Mention API paths byte-for-byte** when you have them — the pre-warm hook will catch them automatically and pre-resolve.
2. **Don't pre-translate route paths** in your questions. Paste them as they appear in logs (`/api/v2/customers/([^/]+)/?`). karmaIQ does exact match — regex form is the canonical key.
3. **Trust subagent delegation**. When firefighter or architect delegates to a subagent, you see one focused summary instead of 8 tool calls cluttering your main chat. Faster *and* cleaner.
4. **Manual-only skills are deliberate**. `/karmaiq-core:setup` and `/karmaiq-promotion-gate:canary` will never fire on their own — you have to type them. Safe by design.
5. **Opt-out env vars** if hooks ever get noisy:
   - `KARMAIQ_NO_PREWARM=1` — disable the UserPromptSubmit pre-warm
   - `KARMAIQ_NO_PRECOMMIT_IMPACT=1` — disable the pre-commit impact warning

---

## Troubleshooting

- **Skill not activating** → run `/reload-plugins`. Check `/skills` lists the skill. Check the description matches your phrasing — try mentioning a service name explicitly.
- **"No domain set"** → run `/karmaiq-core:setup` first.
- **Tool returns "no data"** → widen the time window, verify the domain, re-resolve the name. The plugins follow an Empty-Result Protocol — they'll often surface this themselves.
- **Pre-commit hook didn't fire** → it only fires when **Claude** runs `git commit` via the Bash tool, not when you commit manually in your terminal. For manual coverage, see `plugins/karmaiq-impact/README.md`.

For deeper troubleshooting on a specific plugin, see that plugin's own `README.md`.
