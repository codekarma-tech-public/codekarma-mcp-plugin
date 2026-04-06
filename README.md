# karmaIQ Plugin

This repository contains the configuration needed to integrate [CodeKarma's](https://codekarma.ai) karmaIQ with Cursor IDE and Claude Code. The plugin enables your agents to interact directly with your service mesh, allowing you to analyze service graphs, trace request flows, investigate failures, and monitor service health—all through natural language.

## Features

The karmaIQ MCP server provides the following capabilities:

- **Service Graph Analysis**: Fetch and explore the full service mesh topology, traverse upstream and downstream dependencies, and find paths between services
- **Impact Analysis**: Simulate node failures to determine blast radius, identify single points of failure, and detect circular dependencies
- **Flow Tracing**: Trace end-to-end request paths through the mesh, find critical (highest-latency or highest-traffic) paths, and explore method call hierarchies
- **Service Health**: Check error rates, latency, and throughput for any service, edge, or API endpoint with time-windowed queries
- **Root Cause Investigation**: Identify upstream root cause candidates for failing services, correlate graph-level APIs with method-level flow data, and attribute errors across the dependency graph
- **Code-Level Mapping**: Map HTTP endpoints to implementing code, analyze method execution flows, find dead code, and rank methods by CPU, latency, or error impact

## Prerequisites

Before setting up the karmaIQ MCP server, ensure you have:

- Cursor IDE or Claude Code CLI installed
- A CodeKarma account with access to Karma Insights

## Installation

Choose the installation method for your IDE:

### Claude Code

Run the following command in your terminal:

```bash
claude plugin add -- codekarma-tech/codekarma-mcp-plugin
```

The karmaIQ MCP server will be automatically configured when the plugin loads. You will be prompted to authenticate into your CodeKarma account via OAuth.

The Claude plugin uses the following MCP configuration (`.mcp.json`):

```json
{
  "mcpServers": {
    "karma-iq": {
      "type": "http",
      "url": "https://app.codekarma.tech/mcp/sse"
    }
  }
}
```

### Cursor

You can install from the Cursor Marketplace or follow the steps below to manually configure:

#### Via Marketplace

1. Open Cursor and navigate to **Settings → MCP**
2. Go to the [Cursor Marketplace](https://cursor.com/marketplace)
3. Search for **karmaIQ**
4. Click **Install**
5. Authenticate via OAuth when prompted

#### Manual Configuration

##### Step 1: Open Cursor Settings

Navigate to **Cursor → Settings → Cursor Settings** (or use the keyboard shortcut `Cmd+,` on macOS, `Ctrl+,` on Windows/Linux).

##### Step 2: Navigate to MCP Tab

In the Settings interface, click on the **MCP** tab to access MCP server configurations.

##### Step 3: Add karmaIQ MCP Configuration

Add the following configuration to connect to the remote karmaIQ MCP server:

```json
{
  "mcpServers": {
    "karma-iq": {
      "url": "https://app.codekarma.tech/mcp/sse"
    }
  }
}
```

Save the configuration. You will see a connect button once added. Click that to authenticate into your CodeKarma account.

### Anthropic Connectors Directory (Claude.ai, Claude Desktop)

The karmaIQ MCP server is available directly in Claude without any developer setup.

1. Open [Claude.ai](https://claude.ai) or Claude Desktop
2. Go to **Settings → Connectors**
3. Search for **karmaIQ** or **CodeKarma**
4. Click **Connect**
5. Authenticate via OAuth
6. karmaIQ tools are now available in every Claude conversation

> This channel requires no repo installation. It connects directly to the hosted MCP server and works across Claude.ai, Claude Desktop and Claude Code.

## Available Tools

The karmaIQ MCP server exposes the following tools:

| Tool | Description                                                                                                               |
|------|---------------------------------------------------------------------------------------------------------------------------|
| `get_system_overview` | Get a quick summary of your entire service mesh — how many services, how they connect, and which ones get the most traffic |
| `search_catalog` | Search for any service, API, or method by name — with real time metrics                                                   |
| `traverse_dependencies` | See what a service depends on or what depends on it , helps in determining the criticality and importance                 |
| `find_path` | Find how two services are connected — through all unique flow it takes with metrics                                       |                                       |
| `simulate_failure` | Answer "what breaks if this service goes down?" — see the full blast radius                                               |
| `analyze_architecture` | Find structural problems like circular dependencies, single points of failure, or unused services                         |
| `rank_interfaces` | See which APIs have the most traffic, highest errors, or worst latency                                                    |
| `get_entity_metrics` | Get performance numbers (error rate, latency, throughput) for any service, API, or method                                 |
| `get_api_deep_dive` | Get a full breakdown of a single API — who calls it, what it calls, where errors come from, and what's slow               |
| `root_cause_candidates` | When something is failing, find the most likely cause                                                             |
| `correlate_api_error` | Connect a failing API to the exact methods and code paths causing the issue                                               |
| `map_api` | Find which code handles a specific HTTP endpoint (e.g., who handles `GET /api/orders`)                                    |
| `explore_method_hierarchy` | See what a method calls and what calls it — the full call chain                                                           |
| `analyze_flow` | Dig into a specific execution flow — find the hot path, bottlenecks, or where errors originate                            |
| `analyze_codebase_methods` | Find the most expensive methods in a service — by CPU, latency, errors, or dead code                                      |

## Usage Examples

Once configured, you can interact with your service mesh through your AI assistant using natural language:

- **Explore the mesh**: "Show me an overview of the service graph"
- **Trace dependencies**: "What are the downstream dependencies of the orders service?"
- **Assess blast radius**: "If the payments service goes down, what's the impact?"
- **Investigate failures**: "What's causing the spike in errors on the checkout API?"
- **Find critical paths**: "Show me the highest-latency path between the gateway and the database"
- **Check service health**: "What are the error rates and p99 latency for the user service over the last hour?"
- **Map code to APIs**: "Which controller handles GET /api/v1/orders in the orders service?"
- **Analyze methods**: "What are the top CPU-consuming methods in the payments service?"

## Notes & Limitations

- **Remote server only**: This configuration connects to CodeKarma's hosted MCP server. No local installation is required or supported.
- **Admin approval may be required**: Your organization's CodeKarma administrator must grant access to Karma Insights before you can use this plugin.

## Documentation & Resources

- [CodeKarma](https://codekarma.ai)
- [Plugin Repository](https://github.com/codekarma-tech/codekarma-mcp-plugin)

## Questions or Issues?

For questions about the karmaIQ MCP server or integration issues, please reach out to [info@codekarma.ai](mailto:info@codekarma.ai).
