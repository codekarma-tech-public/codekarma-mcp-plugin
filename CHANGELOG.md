# Changelog

All notable changes to the karmaIQ plugin marketplace.

The format is loosely based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Each plugin tracks its own semver in `plugins/<name>/.claude-plugin/plugin.json`; this file records marketplace-level releases.

## [1.0.0] — 2026-05-14

### Added
- Marketplace manifest at `.claude-plugin/marketplace.json` listing five composable plugins.
- **`karmaiq-core`** (v1.0.0): MCP wiring to `https://app.codekarma.tech/mcp`, domain picker with persistent active-domain state, `exploring-service-mesh` skill, `SessionStart` hook surfacing the active domain.
- **`karmaiq-firefighter`** (v1.0.0): `firefighting-prod-incidents` skill, `karmaiq-firefighter` subagent for autonomous root-cause investigation, three slash skills (`fire`, `rca`, `errors`), `UserPromptSubmit` pre-warm hook detecting API/service mentions (opt-out via `KARMAIQ_NO_PREWARM=1`).
- **`karmaiq-impact`** (v1.0.0): `analyzing-change-impact` skill (path-scoped to code files), `karmaiq-impact-analyzer` subagent with LOW/MED/HIGH risk classifier, three slash skills (`method`, `service`, `path`), `PreToolUse` pre-commit hook on `Bash(git commit *)` that extracts changed method names from the staged diff and injects a warning (opt-out via `KARMAIQ_NO_PRECOMMIT_IMPACT=1`).
- **`karmaiq-architect`** (v1.0.0): `reviewing-system-architecture` skill, `karmaiq-architect` subagent running full-domain audit (SPOF + cycles + orphans + fan + dead-code), five slash skills (`cycles`, `spof`, `deadcode`, `hot`, `fan`).
- **`karmaiq-promotion-gate`** (v1.0.0): `gating-canary-promotion` skill (`disable-model-invocation: true` — manual only), `karmaiq-canary-gate` subagent emitting pipeline-ready verdict JSON, two slash skills (`canary`, `diff`).

### Design rules enforced repo-wide
- Skills never duplicate the karmaIQ server-injected `agent_instructions.md` — they layer persona-specific workflow on top.
- All subagents are read-only (`tools:` whitelists only `mcp__karma-iq__*` tools — no Bash, Edit, Write).
- Route paths preserved byte-for-byte everywhere; regex forms like `/api/v2/foo/([^/]+)/?` never rewritten to `{id}`.
- Active karmaIQ domain persisted at `${CLAUDE_PLUGIN_DATA}/domain.txt` (karmaiq-core); all other plugins read it from the sibling path.
- Hooks fail-silent. Pre-commit hook is warn-only — never blocks commits.
- Promotion-gate skill is `disable-model-invocation: true` so Claude cannot auto-promote a canary by mistake.

### BYOC URL override
- `karmaiq-core/.mcp.json` URL now interpolates `${KARMAIQ_MCP_URL:-https://app.codekarma.tech/mcp}`. Organizations on BYOC (bring-your-own-cloud) karmaIQ deployments set `KARMAIQ_MCP_URL` before launching Claude Code; shared SaaS default applies otherwise.
- `SessionStart` hook in `karmaiq-core` surfaces a custom URL in the active-domain context line so users can confirm which instance they're hitting.

### Removed
- Root-level `.mcp.json` and `.claude-plugin/plugin.json` from the previous single-plugin layout. Users on the old install must re-add the marketplace and install the new plugins individually.

### Channels unchanged
- Cursor (`.cursor-mcp.json`, `.cursor-plugin/plugin.json`) — flat single-server config preserved.
- Anthropic Connectors Directory — no repo-side change required.

[1.0.0]: https://github.com/codekarma-tech/codekarma-mcp-plugin/releases/tag/v1.0.0
