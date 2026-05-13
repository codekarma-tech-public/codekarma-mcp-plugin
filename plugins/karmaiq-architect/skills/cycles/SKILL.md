---
description: Find circular dependencies in the active karmaIQ domain. Manual slash invocation — returns cycles up to length 10, ranked by length and traffic flowing through them.
disable-model-invocation: true
allowed-tools: mcp__karma-iq__analyze_architecture
---

# Circular dependencies in the active domain

## Workflow

1. Read active domain from `${CLAUDE_PLUGIN_DATA}/../karmaiq-core/domain.txt`. If unset → stop and instruct user to run `/karmaiq-core:setup`.
2. Call `analyze_architecture(analysis_type="cycles", max_length=10, max_results=20, domain="<active>")`.
3. Render each cycle as a numbered list with arrow notation (`A → B → C → A`), edge QPM on each hop, and total traffic flowing through.
4. End with prioritization:
   - **HIGH**: cycles with any edge QPM > 0 (traffic is actually flowing through the loop)
   - **LOW**: cycles with all edges at 0 QPM (structural but inactive)
5. Suggest: *"For impact analysis on breaking the cycle, run `/karmaiq-impact:service <node>` on any node in the top HIGH cycle."*
