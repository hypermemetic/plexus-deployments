# Substrate Deployments - Quick Start

Get the entire Substrate ecosystem running in 5 minutes!

## Prerequisites

- Docker 20.10+
- Docker Compose 2.0+
- Git

## Option 1: Automated Setup (Recommended)

```bash
# 1. Clone this repo
git clone <repo-url> substrate-deployments
cd substrate-deployments

# 2. Clone required service repos (or set paths to existing clones)
cd ..
git clone <substrate-url> substrate
git clone <registry-url> registry
git clone <auth-hub-url> auth-hub
# ... clone other dependencies

# 3. Run automated setup
cd substrate-deployments
./docker-quick-start.sh
```

The script will:
- ✓ Check dependencies
- ✓ Build base image with synapse
- ✓ Build all service images
- ✓ Create secrets directory
- ✓ Start all services

## Option 2: Manual Setup

### Standard Stack (Full Features)

```bash
cd standard

# Configure paths to your repos
cp .env.example .env
# Edit .env with your repo paths

# Build and start
make build-base
make build
make up

# Check status
make health
```

### Minimal Stack (Just Substrate Hub)

```bash
cd minimal

# Set substrate path
export SUBSTRATE_PATH=../../substrate

# Start
docker-compose up -d
```

## Verify It's Running

```bash
# Check containers
docker-compose ps

# View logs
docker-compose logs -f

# Test substrate (if synapse installed locally)
synapse -P 4444 plexus health check
```

## What You Get

### Standard Stack
- **Substrate Hub** at `ws://localhost:4444`
- **Registry** at `ws://localhost:4445`
- **Auth Hub** at `ws://localhost:4446`

### Minimal Stack
- **Substrate Hub** at `ws://localhost:4444`

## Using the Services

### Substrate Hub

```bash
# List all activations
synapse -P 4444 plexus

# Health check
synapse -P 4444 plexus health check

# Try the echo service
synapse -P 4444 plexus echo once --message "Hello!"
```

### Auth Hub (Standard Stack)

```bash
# Set a secret
synapse -P 4446 secrets auth set_secret \
  --secret-key github/mytoken \
  --value ghp_xxxxxxxxxxxxx

# Get a secret
synapse -P 4446 secrets auth get_secret \
  --secret-key github/mytoken

# List all secrets
synapse -P 4446 secrets auth list_secrets --prefix ""
```

### Registry (Standard Stack)

```bash
# List registered backends
synapse -P 4445 registry registry list
```

## Makefile Commands (Standard Stack)

```bash
make help          # Show all commands
make build-base    # Build base image
make build         # Build services
make up            # Start services
make down          # Stop services
make logs          # View all logs
make health        # Check service health
make test          # Run tests
make clean         # Remove volumes
make shell-*       # Open shell in container
```

## Directory Structure

```
substrate-deployments/
├── base/                       # Base images
│   └── Dockerfile.synapse      # Synapse base image
├── standard/                   # Full stack
│   ├── docker-compose.yml
│   ├── Makefile
│   ├── .env.example
│   └── secrets/                # Auth hub secrets
├── minimal/                    # Minimal stack
│   └── docker-compose.yml
├── custom/                     # Custom architectures
│   └── examples/
│       ├── edge-stack.yml      # Low-resource
│       └── dev-stack.yml       # Development
└── docs/                       # Documentation
    ├── architecture.md
    └── development.md
```

## Next Steps

1. **Configure Secrets**: Edit `standard/secrets/secrets.yaml`
2. **Explore Services**: Try different activations
3. **Read Docs**: See `README.md` and `docs/` for details
4. **Customize**: Create your own architecture in `custom/`

## Troubleshooting

### "Cannot find repository"

Set paths in `.env`:
```bash
SUBSTRATE_PATH=/absolute/path/to/substrate
```

### "Port already in use"

Change ports in `.env`:
```bash
SUBSTRATE_PORT=5444
```

### Service won't start

```bash
# Check logs
docker-compose logs substrate

# Rebuild
docker-compose build substrate
docker-compose up -d
```

### Complete reset

```bash
make clean-all
make build-base
make build
make up
```

## Architecture Options

### Standard (Full Features)
```bash
cd standard && make up
```
Memory: ~1GB, Services: 3

### Minimal (Lightweight)
```bash
cd minimal && docker-compose up -d
```
Memory: ~300MB, Services: 1

### Edge (Low Resource)
```bash
cd custom
docker-compose -f examples/edge-stack.yml up -d
```
Memory: ~400MB, Services: 2

### Dev (Hot Reload)
```bash
cd custom
docker-compose -f examples/dev-stack.yml up -d
```
Memory: ~1.5GB, Services: 3 + tools

## Getting Help

- Read `README.md` for full documentation
- Check `docs/architecture.md` for architecture details
- See `docs/development.md` for development guide
- Open an issue on GitHub

## What's Next?

After getting comfortable:
- Try different architectures in `custom/examples/`
- Create your own custom architecture
- Deploy to production (see docs/production.md - coming soon)
- Integrate with your applications

Happy deploying! 🚀
