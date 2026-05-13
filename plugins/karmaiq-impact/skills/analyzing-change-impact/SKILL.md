---
description: Compute blast radius before changing code. Loads in code files (Python, Go, Java, TypeScript, JavaScript, Ruby) or when the user mentions refactor, rename, delete, move, modify, "is it safe to change", "what depends on X", "who calls Y", or staged changes. Delegates multi-method/multi-service runs to the karmaiq-impact-analyzer subagent.
paths: ["**/*.py", "**/*.go", "**/*.java", "**/*.ts", "**/*.tsx", "**/*.js", "**/*.jsx", "**/*.rb"]
allowed-tools: mcp__karma-iq__*
---

# Analyzing change impact with karmaIQ

The user is in (or about to enter) code that may have production callers. Before they refactor, rename, delete, or modify, surface the blast radius.

## Decide: subagent or inline

**Delegate to `karmaiq-impact-analyzer` subagent (preferred for multi-target).** Use the Task tool with `subagent_type=karmaiq-impact-analyzer` whenever:

- The user is renaming/deleting/refactoring 2+ methods or a class
- A pre-commit hook injected a list of changed methods to check
- The user asked about service-level change ("can we replace X service")
- The investigation requires graph + code-path correlation

Pass the targets verbatim. Subagent returns a ranked dependents table per target.

**Stay inline only when:**

- Single method or single service
- User already has the exact `node_id` or method hash
- User explicitly asks to keep it in the main chat

## Inline workflow

### For a method
```
1. search_catalog(catalog="service", class_names=[<class>])   # → service_name
2. analyze_code_path_impact(service_name=<resolved>, query="<Class.method>", include_flows=true)
3. Render: direct callers, transitive callers, amplification flags, top affected flows
```

### For a service
```
1. search_catalog(catalog="graph", query="<service>")   # → node_id
2. simulate_failure(node_id=<resolved>, detail="summary")   # ranked blast counts
3. simulate_failure(node_id=<resolved>, detail="full", top_k=20)   # ranked QPM-lost
4. Render: top 5 affected interfaces, total QPM impact, amplification flags >2×
```

### For "what depends on X"
- API/service: `traverse_dependencies(direction="upstream")`
- Method: `explore_code_path(direction="callers")`

Read the active domain from `${CLAUDE_PLUGIN_DATA}/../karmaiq-core/domain.txt`. Pass `domain=...` on every call.

## Output template

```
## Finding
<is it safe / risky / load-bearing — 1 line>

## Evidence
<table of top dependents with QPM, amplification, and risk classification>

## Next step
<one concrete action: review the top caller, add a deprecation, or proceed safely>
```

## Risk classification

| Class | Criteria |
|---|---|
| **LOW** | <50 QPM total dependent traffic, no amplification > 2× |
| **MED** | 50–500 QPM OR amplification 2–4× on any edge |
| **HIGH** | >500 QPM OR amplification > 4× OR appears in any critical path |

## Hard rules

1. Never assume a method is unused based on absence of callers in the file you're reading. Always confirm via `explore_code_path(direction="callers")` first.
2. Preserve method names, class names, and service names byte-for-byte. The system does exact string match.
3. If `search_catalog(catalog="service")` returns multiple owning services, ask the user to clarify rather than guessing.
4. Read active domain from `${CLAUDE_PLUGIN_DATA}/../karmaiq-core/domain.txt`. If unset, tell user to run `/karmaiq-core:setup` and stop.

## Forbidden

- Mutating anything (this plugin is read-only)
- Calling `simulate_failure` with `failure_type="errors"` as a substitute for `regression_diff` — different tool, different purpose
- Using code-path tools to ask about latency (no latency at the code layer)
- Recommending a change as "safe" without showing the evidence table
