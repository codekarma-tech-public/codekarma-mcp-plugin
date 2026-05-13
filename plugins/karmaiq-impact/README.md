# karmaiq-impact

> Pre-change blast-radius analysis. Know who calls what — in production — before you change it.

## Why this plugin

Renames, refactors, and "this method looks unused" decisions are made every day inside the IDE with zero awareness of production traffic. This plugin pulls the karmaIQ method-level call graph in at the right moment:

- When you're editing code in `.py`/`.go`/`.java`/`.ts`/`.tsx`/`.js`/`.jsx`/`.rb` files, the `analyzing-change-impact` skill is on standby.
- When Claude runs `git commit` via the Bash tool, the pre-commit hook scans the staged diff for changed method definitions and warns about ones that look load-bearing.
- Slash commands run impact checks on demand.

## Install

Requires `karmaiq-core` for the MCP connection. Install both:

```
/plugin install karmaiq-core@karmaiq
/plugin install karmaiq-impact@karmaiq
```

## How it works

1. **Path-scoped skill** — `analyzing-change-impact` auto-loads only when the working file matches a code-language glob. Outside code files, this plugin is silent.
2. **Pre-commit hook** (`PreToolUse` on `Bash(git commit *)`) — extracts changed method/function names from `git diff --cached`, injects an `additionalContext` hint listing them and recommending an impact check before the commit lands. **Warn-only** — does not block. Set `KARMAIQ_NO_PRECOMMIT_IMPACT=1` to disable.
3. **`karmaiq-impact-analyzer` subagent** — for multi-method or multi-service impact runs. Returns a ranked dependents table per target.
4. **Slash commands** for direct impact queries.

## Commands

| Command | What |
|---|---|
| `/karmaiq-impact:method <service> <method>` | Blast radius of changing a single method (callers, callees, amplification). |
| `/karmaiq-impact:service <service>` | Service-level impact via `simulate_failure` — what breaks if this service goes down. |
| `/karmaiq-impact:path <from> <to>` | Show all paths between two services. |

## Example: Claude about to commit

> **Claude (about to run)**: `git commit -m "refactor PaymentProcessor"`
>
> *(PreToolUse hook fires — scans staged diff)*
>
> *(hook injects:* `karmaIQ pre-commit: 2 method definitions changed in 1 staged file — PaymentProcessor.charge, PaymentProcessor.refund. Recommend running /karmaiq-impact:method payments-service charge before committing if these handle production traffic.`*)*
>
> **Claude** *(reading hint)*: "I noticed the staged diff modifies `charge` and `refund` in `payments-service`. Let me check the blast radius first." → invokes `karmaiq-impact-analyzer` subagent → returns dependents table → user decides.

## Coverage limit

The PreToolUse hook only fires when **Claude** runs `git commit` (via the Bash tool). It does **not** fire when you commit manually in your terminal — Claude Code hooks live inside CC sessions only.

For manual commit coverage, install a real git pre-commit hook that calls the same `precommit-impact.sh` script. Example (run once at repo root):

```bash
ln -s "$(pwd)/path/to/karmaiq-impact/hooks/precommit-impact.sh" .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

Note: the script expects CC hook stdin JSON; the manual-hook path is documented but not wired by default.

## Safety

- Subagent has **read-only** karmaIQ tools — cannot run Bash, edit files, or call other MCP servers.
- Pre-commit hook is **warn-only**. It never blocks the commit. Future versions may add `KARMAIQ_IMPACT_BLOCK_ON=high` to opt into hard-block on HIGH-impact methods.

## Troubleshooting

- **Hook didn't fire on commit** → check `KARMAIQ_NO_PRECOMMIT_IMPACT` isn't set. Verify your commit was Claude-initiated (`Bash` tool), not a terminal command.
- **No methods detected** → diff parsing is heuristic. Function names without conventional signatures (e.g. arrow functions assigned to variables) may slip through.
- **Slash command says "no domain set"** → run `/karmaiq-core:setup` first.
