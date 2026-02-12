# Minimal Stack - Substrate Hub Only

Lightweight deployment with just the Substrate Hub. Perfect for:
- Development and testing
- When you only need the core hub functionality
- Minimal resource usage
- Quick prototyping

## Services

- **Substrate Hub** (port 4444) - Main plugin hub with all activations

## Quick Start

```bash
# Set the path to your substrate repo
export SUBSTRATE_PATH=~/path/to/substrate

# Start the hub
docker-compose up -d

# Check it's running
docker-compose logs -f
```

## Usage

Once running, access substrate at `ws://localhost:4444`:

```bash
# Using synapse (if installed locally)
synapse -P 4444 substrate health check

# Or from inside the container
docker-compose exec substrate synapse -P 4444 substrate health check
```

## Configuration

Create a `.env` file:

```bash
SUBSTRATE_PORT=4444
SUBSTRATE_PATH=../../substrate
RUST_LOG=info
```

## Resource Usage

Approximate:
- **Memory**: ~300MB
- **CPU**: Minimal when idle
- **Disk**: ~100MB (container + volumes)

## Activations Included

The substrate hub includes all built-in activations:
- substrate - Core routing
- solar - Example nested plugin
- cone - LLM conversation manager
- claudecode - Claude Code session manager
- jsexec - JavaScript execution
- hyperforge - Multi-forge repo management
- echo - Simple echo service
- arbor - Conversation tree storage
- changelog - Schema change tracking
- health - Health checks
- mustache - Template rendering
- loopback - Permission routing
- bash - Bash command execution

For secret management, use the [standard stack](../standard/README.md) which includes auth-hub.
