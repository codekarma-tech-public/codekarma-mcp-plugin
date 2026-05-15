---
description: Pick the active karmaIQ domain. Manual setup — run on first install or when switching domains. Calls list_domains, asks the user to choose, persists the selection across sessions.
disable-model-invocation: true
allowed-tools: mcp__karma-iq__list_domains
---

# Pick active karmaIQ domain

Setup flow for first install or domain switching.

## Steps

1. Read the current value from `${CLAUDE_PLUGIN_DATA}/domain.txt` if it exists.
2. Call `mcp__karma-iq__list_domains` with no arguments.
3. Show the user the list as a numbered choice. If a current value exists, mark it as the current selection.
4. Ask: *"Which domain do you want active for this and future sessions?"*
5. Once the user names a domain (by number or name), write the resolved domain name to `${CLAUDE_PLUGIN_DATA}/domain.txt`. Create the parent directory if it doesn't exist.
6. Confirm: *"Active karmaIQ domain set to `<name>`. All karmaIQ tools will now query this domain. Switch later with `/karmaiq-core:domain <other-name>`."*
7. Emit the **install-the-rest block verbatim** as a final step. The user copies and runs each line to complete the karmaIQ install. Render exactly:

   ````
   Install the rest of karmaIQ:

   ```
   /plugin install karmaiq-firefighter@karmaiq
   /plugin install karmaiq-impact@karmaiq
   /plugin install karmaiq-architect@karmaiq
   /plugin install karmaiq-promotion-gate@karmaiq
   ```

   Or pick by persona — see README.md.
   ````

   Reasoning: Claude Code skills cannot programmatically invoke `/plugin install` (not in the Skill-tool whitelist), so we hand the user a one-shot copy-paste block.

## Error handling

- If `list_domains` returns an empty list or errors, surface the error verbatim and suggest: *"Your CodeKarma admin may not have granted access yet. Contact info@codekarma.ai or your org admin."*
- If the user names a domain that isn't in the list, ask for confirmation before writing — they may know about a domain that listed late.
