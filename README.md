# Substrate Deployments

Infrastructure and deployment configurations for the Substrate ecosystem.

This repository contains Docker Compose configurations, Dockerfiles, and orchestration scripts for deploying various Substrate ecosystem architectures.

## Overview

Substrate Deployments is a meta-repository that references other Substrate ecosystem repositories to build and deploy custom architectures. It allows you to:

- 🏗️ **Build custom stacks** - Mix and match services from different repos
- 🐳 **Deploy with Docker** - Complete Docker Compose configurations
- 🔧 **Multiple architectures** - Different deployment patterns for different use cases
- 📦 **Reference-based** - Pulls source from individual repos, doesn't duplicate code

## Architecture Configurations

### Standard Stack (`standard/`)
The complete Substrate ecosystem with all core services.

**Services:**
- Substrate Hub (port 4444) - Main plugin hub
- Registry (port 4445) - Backend discovery
- Auth Hub (port 4446) - Secret management

### Minimal Stack (`minimal/`)
Lightweight deployment with just substrate hub.

### Claude Container (`claude-container/`)
Development container for Claude Code sessions. Includes host-side scripts for exposing services (e.g., ChromeDriver) to containers. See [claude-container/README.md](claude-container/README.md).

### Custom Stacks
Create your own by mixing services in `custom/`.

## Quick Start

```bash
# Clone this repo
git clone <repo-url> substrate-deployments
cd substrate-deployments

# Deploy the standard stack
cd standard
make deploy

# Or use docker-compose directly
docker-compose up -d
```

## Repository Structure

```
substrate-deployments/
├── README.md                    # This file
├── base/                        # Base images and shared resources
│   ├── Dockerfile.synapse       # Base image with Synapse CLI
│   └── scripts/                 # Shared scripts
├── standard/                    # Full substrate stack
│   ├── docker-compose.yml
│   ├── Makefile
│   ├── README.md
│   └── config/
├── minimal/                     # Minimal deployment
│   ├── docker-compose.yml
│   └── README.md
├── claude-container/             # Claude Code dev container
│   ├── Dockerfile
│   ├── claude-projects.yml
│   ├── README.md
│   └── scripts/
│       └── start-chromedriver.sh
├── custom/                      # Custom architecture templates
│   └── examples/
└── docs/                        # Documentation
    ├── architecture.md
    ├── development.md
    └── production.md
```

## How It Works

This repo uses **build contexts** to reference external repositories:

```yaml
# docker-compose.yml
services:
  substrate:
    build:
      context: /path/to/substrate-repo
      dockerfile: Dockerfile
```

For production deployments, you can:
1. Clone required repos as submodules
2. Use git sparse-checkout for specific paths
3. Reference local paths during development

## Deployment Patterns

### Local Development
```bash
cd standard
export SUBSTRATE_PATH=~/dev/substrate
export REGISTRY_PATH=~/dev/registry
export AUTH_HUB_PATH=~/dev/auth-hub
docker-compose up
```

### Production (with submodules)
```bash
git submodule update --init --recursive
cd standard
docker-compose -f docker-compose.prod.yml up -d
```

### CI/CD
See `docs/ci-cd.md` for GitHub Actions, GitLab CI examples.

## Requirements

- Docker 20.10+
- Docker Compose 2.0+
- Git (for cloning referenced repos)

## Environment Variables

Create a `.env` file in each architecture directory:

```bash
# .env example
SUBSTRATE_PORT=4444
REGISTRY_PORT=4445
AUTH_HUB_PORT=4446

# Repository paths (for local development)
SUBSTRATE_PATH=../substrate
REGISTRY_PATH=../registry
AUTH_HUB_PATH=../auth-hub

# Build configuration
BUILD_PARALLEL=true
RUST_LOG=info
```

## Contributing

Add new architectures by:
1. Creating a new directory (e.g., `edge-stack/`)
2. Adding `docker-compose.yml` and `README.md`
3. Documenting the use case and services included

## License

MIT

## Related Repositories

- [substrate](https://github.com/hypermemetic/substrate) - Main plugin hub
- [registry](https://github.com/hypermemetic/registry) - Backend discovery
- [auth-hub](https://github.com/hypermemetic/auth-hub) - Secret management
- [synapse](https://github.com/hypermemetic/synapse) - Schema-driven CLI
- [hub-core](https://github.com/hypermemetic/hub-core) - Core hub framework
- [hub-macro](https://github.com/hypermemetic/hub-macro) - Macro system
- [hub-transport](https://github.com/hypermemetic/hub-transport) - Transport layer
