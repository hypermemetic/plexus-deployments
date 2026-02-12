# Docker Setup - Complete Summary

## What Was Created

### Core Docker Files

1. **`Dockerfile.base`** - Base image with Haskell/Cabal and Synapse
   - Multi-stage build for optimal size
   - Contains synapse CLI tool pre-installed at `/usr/local/bin/synapse`
   - Based on Debian Bookworm Slim
   - Tagged as: `ghcr.io/hypermemetic/substrate-base:latest`

2. **`docker-compose.yml`** - Orchestration for all services
   - 3 services: substrate, registry, auth-hub
   - Bridge network: `substrate-net`
   - Volumes for persistence:
     - `registry-config` - Registry configuration
     - `registry-data` - Registry SQLite database
     - `./secrets` - Auth-hub secrets (host mount)
   - Health checks for all services
   - Auto-restart policy

### Service Dockerfiles

3. **`substrate/Dockerfile`** - Substrate Hub container
   - Multi-stage Rust build
   - Exposes ports: 4444 (WebSocket), 4445 (MCP - disabled)
   - Includes both `substrate` and `mcp-gateway` binaries
   - Based on substrate-base image

4. **`registry/Dockerfile`** - Registry Service container
   - Multi-stage Rust build
   - Exposes port: 4445 (WebSocket)
   - Volumes: `/data` and `/config`
   - Based on substrate-base image

5. **`auth-hub/Dockerfile`** - Auth Hub container
   - Multi-stage Rust build
   - Exposes port: 4446 (WebSocket)
   - Volume: `/config/auth-hub` for secrets.yaml
   - Based on substrate-base image

### Helper Files

6. **`Makefile`** - Quick commands for common tasks
   - `make help` - Show all commands
   - `make build-base` - Build base image
   - `make build` - Build all services
   - `make up` - Start services
   - `make down` - Stop services
   - `make logs` - View logs
   - `make health` - Check service health
   - `make test` - Run test commands
   - And many more...

7. **`docker-quick-start.sh`** - Automated setup script
   - Checks for Docker/Docker Compose
   - Builds base image
   - Builds service images
   - Creates secrets directory
   - Starts all services
   - Shows status and usage

8. **`README.docker.md`** - Comprehensive documentation
   - Architecture overview
   - Quick start guide
   - Usage examples
   - Service management
   - Volume management
   - Troubleshooting
   - Production considerations

9. **`.dockerignore`** - Optimizes build context
   - Excludes build artifacts
   - Excludes documentation
   - Excludes tests and examples
   - Excludes git and IDE files

10. **`.gitignore`** - Updated for Docker setup
    - Ignores secrets directory (except .gitkeep)
    - Ignores backups
    - Ignores .env files

11. **`secrets/`** - Directory for auth-hub secrets
    - `.gitkeep` - Keeps directory in git
    - `secrets.yaml.example` - Example secrets configuration
    - `secrets.yaml` - Actual secrets (not committed)

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│              ghcr.io/hypermemetic/substrate-base            │
│                  (Debian + Synapse CLI)                     │
└──────────────┬──────────────┬──────────────┬────────────────┘
               │              │              │
       ┌───────▼─────┐ ┌──────▼──────┐ ┌────▼────────┐
       │  substrate  │ │  registry   │ │  auth-hub   │
       │  (Port 4444)│ │ (Port 4445) │ │ (Port 4446) │
       └─────────────┘ └─────────────┘ └─────────────┘
               │              │              │
               └──────────────┼──────────────┘
                              │
                      substrate-net
                      (Docker Network)
```

## Quick Start Commands

```bash
# Method 1: Using the quick start script (recommended)
./docker-quick-start.sh

# Method 2: Using Make
make build-base    # Build base image
make build         # Build all services
make up            # Start services
make health        # Check health
make logs          # View logs

# Method 3: Manual steps
docker build -f Dockerfile.base -t ghcr.io/hypermemetic/substrate-base:latest .
docker-compose build
docker-compose up -d
```

## Service Endpoints

Once running, services are available at:

| Service | Protocol | Port | Endpoint |
|---------|----------|------|----------|
| Substrate Hub | WebSocket | 4444 | `ws://localhost:4444` |
| Registry | WebSocket | 4445 | `ws://localhost:4445` |
| Auth Hub | WebSocket | 4446 | `ws://localhost:4446` |

## Usage Examples

### From Host (if synapse installed)

```bash
# Substrate - health check
synapse -H localhost -P 4444 substrate health check

# Auth Hub - manage secrets
synapse -H localhost -P 4446 secrets auth set_secret \
  --secret-key github/token --value ghp_xxx
```

### From Container

```bash
# Execute commands inside containers
docker-compose exec substrate synapse -P 4444 substrate health check
docker-compose exec auth-hub synapse -P 4446 secrets auth list_secrets --prefix ""
```

## Volume Mounts

| Service | Host Path | Container Path | Purpose |
|---------|-----------|----------------|---------|
| auth-hub | `./secrets` | `/config/auth-hub` | Persistent secrets storage |
| registry | `registry-config` (volume) | `/config` | Registry configuration |
| registry | `registry-data` (volume) | `/data` | Registry database |

## File Sizes (Approximate)

| File | Size | Description |
|------|------|-------------|
| Base Image | ~500MB | Debian + GHC + Cabal + Synapse |
| Substrate Image | ~600MB | Base + Substrate binary |
| Registry Image | ~550MB | Base + Registry binary |
| Auth Hub Image | ~550MB | Base + Auth-hub binary |

## Build Times (Approximate)

| Step | First Build | Subsequent |
|------|-------------|------------|
| Base Image | 15-20 min | Cached |
| Substrate | 5-10 min | 1-2 min |
| Registry | 3-5 min | 1 min |
| Auth Hub | 3-5 min | 1 min |

## Next Steps

1. **Configure Secrets**: Edit `secrets/secrets.yaml` with your actual secrets
2. **Customize Ports**: Edit `docker-compose.yml` if you need different ports
3. **Production Setup**: Review `README.docker.md` for production considerations
4. **Monitor**: Use `make logs` or `docker-compose logs -f`
5. **Test**: Use `make test` to verify everything works

## Common Commands

```bash
# Start everything
make up

# View logs
make logs
make logs-substrate
make logs-registry
make logs-auth

# Health check
make health

# Run tests
make test

# Stop everything
make down

# Clean up
make clean

# Complete rebuild
make rebuild

# Backup secrets
make secrets-backup

# Open shell
make shell-substrate
make shell-registry
make shell-auth
```

## Troubleshooting

See `README.docker.md` for comprehensive troubleshooting guide.

Quick fixes:
```bash
# Service won't start
docker-compose logs <service-name>

# Complete reset
make clean-all
make build-base
make build
make up

# Port already in use
docker-compose down
# Edit docker-compose.yml to change ports
docker-compose up -d
```

## Files Created Summary

```
/workspace/
├── Dockerfile.base              # Base image with synapse
├── docker-compose.yml           # Service orchestration
├── Makefile                     # Quick commands
├── docker-quick-start.sh        # Automated setup
├── README.docker.md             # Full documentation
├── .dockerignore                # Build optimization
├── .gitignore                   # Git ignore rules
├── secrets/                     # Auth secrets directory
│   ├── .gitkeep
│   └── secrets.yaml.example
├── substrate/
│   └── Dockerfile               # Substrate image
├── registry/
│   └── Dockerfile               # Registry image
└── auth-hub/
    └── Dockerfile               # Auth-hub image
```

## License

Individual service licenses:
- substrate: AGPL-3.0-only
- registry: AGPL-3.0-only
- auth-hub: MIT
