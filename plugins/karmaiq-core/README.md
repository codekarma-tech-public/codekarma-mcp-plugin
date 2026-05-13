# karmaiq-core

> Baseline karmaIQ MCP connection plus active-domain management. **Install this first** — every other karmaIQ plugin assumes it.

## What this plugin gives you

- **MCP connection** to `https://app.codekarma.tech/mcp`. OAuth handshake on first use.
- **Active-domain picker**: pick which CodeKarma domain to query. Choice is persisted across sessions in `${CLAUDE_PLUGIN_DATA}/domain.txt`.
- **`exploring-service-mesh` skill**: auto-loads when you mention a service or API, ensuring Claude follows karmaIQ's bootstrap/resolve/time-window protocol before any tool call.
- **`SessionStart` hook**: each new session surfaces the active domain (or prompts setup if none).

## Install

```
/plugin install karmaiq-core@karmaiq
```

On first session, you'll see: *"karmaIQ domain not set yet. Run /karmaiq-core:setup to pick one."*

## Commands

| Command | Purpose |
|---|---|
| `/karmaiq-core:setup` | List available domains via `list_domains`, pick one, persist it |
| `/karmaiq-core:overview` | Snapshot of the active domain — nodes, edges, top services, top errors |
| `/karmaiq-core:domain [name]` | Show current active domain, or switch by passing a name |

## How the auto-skill activates

The `exploring-service-mesh` skill is **model-invocable** — Claude loads it automatically whenever your message mentions a service, API endpoint, or production behavior. It enforces three habits:

1. `get_system_overview` first per session
2. `search_catalog(catalog="graph")` to resolve any service/API name before downstream calls
3. `get_time_intervals` before any temporal query

It also routes intent to the right specialized plugin (firefighter / impact / architect / promotion-gate).

## Skip permission prompts for karmaIQ tools

karmaIQ is a read-only layer — every tool is safe to auto-allow. Three options:

**1. Automatic via skill frontmatter (already shipped).** Every karmaIQ skill declares `allowed-tools: mcp__karma-iq__*` in its frontmatter. While a karmaIQ skill is active, all karmaIQ tool calls are pre-approved — no prompt.

**2. Plugin-shipped settings (best-effort).** This plugin ships `settings.json` with `permissions.allow: ["mcp__karma-iq__*"]`. Future CC versions that honor plugin permissions will pick this up automatically.

**3. Project- or user-level allowlist (most reliable today).** Add to `~/.claude/settings.json` (global) or `.claude/settings.json` (per-project):

```json
{
  "permissions": {
    "allow": [
      "mcp__karma-iq__*"
    ]
  }
}
```

After saving, restart CC or run `/reload-plugins`. No more permission prompts for karmaIQ tools.

## BYOC instance (override default URL)

By default this plugin connects to the shared SaaS endpoint at `https://app.codekarma.tech/mcp`. For BYOC (bring-your-own-cloud) karmaIQ deployments running on your own infrastructure, set `KARMAIQ_MCP_URL` before launching Claude Code:

```bash
export KARMAIQ_MCP_URL=https://<your-byoc-domain>/mcp
claude
```

The `.mcp.json` uses `${KARMAIQ_MCP_URL:-https://app.codekarma.tech/mcp}` — env var if set, default otherwise. When a custom URL is active, the `SessionStart` hook surfaces it so you see which instance you're hitting.

To persist across sessions, add to your shell rc, `.envrc` (direnv), or CC `settings.json` `env` block.

## Requirements

- Active CodeKarma account
- Karma Insights access granted by your org admin (your domains will appear in `list_domains`)
- Claude Code v2.1+ (plugin marketplace support)

## Troubleshooting

- **"No domains returned"** → check OAuth status; your admin may not have granted access yet.
- **Wrong domain selected** → run `/karmaiq-core:domain <new-name>` to switch.
- **Skill not activating on service names** → run `/reload-plugins` and check `/skills` lists `karmaiq-core:exploring-service-mesh`.
