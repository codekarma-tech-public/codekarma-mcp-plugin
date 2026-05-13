# AGENTS.md — contributor guide for karmaIQ plugins

## Quick rules

- **One plugin per change.** Don't edit multiple plugins in a single PR unless explicitly requested.
- **No secrets ever.** Auth is OAuth at runtime via the karmaIQ MCP server.
- **Smallest viable change.** Improve correctness, safety, or docs — don't refactor adjacent code.
- **Preserve user verbatim.** Route paths, node_ids, exception names — echo byte-for-byte.

## Plugin anatomy

Every plugin lives at `plugins/<plugin-name>/` and must have:

```
plugins/<name>/
├── .claude-plugin/plugin.json   # required
├── README.md                     # required — purpose, commands, example
├── skills/<skill>/SKILL.md       # optional — capability definitions
├── agents/<agent>.md             # optional — subagents
├── hooks/hooks.json + *.sh       # optional — event handlers
├── .mcp.json                     # optional — only karmaiq-core has this today
└── references/                   # optional — deep docs, human-browse only
```

### `plugin.json` schema (minimum)

```json
{
  "name": "karmaiq-<scope>",
  "description": "<one sentence; states what loads and when>",
  "version": "<semver>",
  "author": {"name": "CodeKarma", "email": "info@codekarma.ai", "url": "https://codekarma.ai"},
  "homepage": "https://codekarma.ai",
  "repository": "https://github.com/codekarma-tech/codekarma-mcp-plugin",
  "license": "MIT",
  "keywords": ["mcp", "karmaiq", ...]
}
```

## Skill authoring rules

1. **Filename**: `SKILL.md` (uppercase) inside `skills/<gerund-noun>/`.
2. **Frontmatter**:
   - `description` (required, third person) — Claude uses this to match user intent. Lead with the key trigger scenario, then keywords. ≤1536 chars (server truncates).
   - `disable-model-invocation: true` for slash-only manual skills (e.g. setup, deploy gates).
   - `allowed-tools` — restrict to the karmaIQ MCP tools the skill actually uses. Don't grant Bash/Edit unless necessary.
   - `paths` — glob to scope auto-load (e.g. `["**/*.py","**/*.go"]` for code-change skills).
   - `argument-hint` — for `$ARGUMENTS` skills.
3. **Body**:
   - ≤200 lines for auto-invoked skills (content stays in context once loaded).
   - **Never re-state the karmaIQ tool reference.** Server auto-injects `agent_instructions.md` at handshake.
   - Always include an output template (Finding / Evidence / Next step) for analytical skills.
   - State route-path preservation rule if the skill touches routes.

## Subagent authoring rules

1. File: `agents/<name>.md`. Frontmatter: `name`, `description`, `tools`, `model`.
2. `tools` must be an explicit list of `mcp__karma-iq__*` tool names — never `*`, never Bash/Edit/Write.
3. Body = system prompt. Include:
   - Persona statement (1–2 sentences)
   - Hard rules (numbered, no preamble)
   - Default workflow (numbered steps)
   - Return format (Finding / Evidence / Next step)
   - Forbidden list (anti-patterns)
4. Use `description` keywords that match Claude's delegation logic — name the symptoms (e.g. "API errors", "service down", "latency spike").

## Hook authoring rules

- Pure bash. No jq dependency (try-then-fallback if needed).
- Read JSON from stdin. Best-effort extract — never assume schema.
- Exit 0 on any internal error. Stderr goes to user transcript.
- Exit 2 only to **deliberately** block, with a clear message. Document the trigger.
- Honor opt-out env vars (`KARMAIQ_NO_<HOOK>=1`).
- Timeout: SessionStart/UserPromptSubmit ≤3s; PreToolUse ≤30s.

## What NOT to do

- Don't add MCP servers in plugins other than `karmaiq-core`. One server, one wiring.
- Don't duplicate `agent_instructions.md` content in skills. Server already injects it.
- Don't make subagents that can mutate (Bash, Edit, Write). karmaIQ is read-only.
- Don't rewrite route paths in any output. `([^/]+)` stays `([^/]+)`.
- Don't add a hook that auto-fires API calls at session start. SessionStart is for setup hints only.
- Don't compute epochs from local clock anywhere — use `mcp__karma-iq__get_time_intervals`.

## Testing

Local:

```bash
claude --plugin-dir ./plugins/karmaiq-core --plugin-dir ./plugins/karmaiq-firefighter
```

In session: `/reload-plugins` after edits. Verify:

- Slash commands appear in `/plugin-name:` autocomplete
- Skills appear in `/skills` listing with correct descriptions
- Subagents appear in `/agents` listing
- Hooks fire when expected (check transcript)

## Release / versioning

- Bump `version` in `plugins/<name>/.claude-plugin/plugin.json` for any user-visible change.
- Mirror in marketplace.json entry.
- Update `CHANGELOG.md` at repo root.
- Commit on `main`; users on git-based marketplaces pull automatically on next session.
