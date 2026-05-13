---
description: Show the currently active karmaIQ domain, or switch by passing a domain name. Persists across sessions.
disable-model-invocation: true
argument-hint: "[new-domain-name]"
---

# Show or switch active karmaIQ domain

## Logic

- **No `$ARGUMENTS`**: read `${CLAUDE_PLUGIN_DATA}/domain.txt`. If it exists, report the value: *"Active karmaIQ domain: `<name>`."* If it does not exist, say: *"No karmaIQ domain set — run `/karmaiq-core:setup` first."*

- **`$ARGUMENTS` given**: write the value to `${CLAUDE_PLUGIN_DATA}/domain.txt` (create parent dir if missing), and confirm: *"Active karmaIQ domain switched to `<name>`. All karmaIQ tools will query this domain."*

## Note

This skill does **not** validate the name against `list_domains` — use `/karmaiq-core:setup` for an interactive picker. This command is for fast switches when you already know the target domain name.
