# Substrate Ecosystem - Docker Deployment

Run the entire substrate ecosystem (substrate hub, registry, auth-hub) with Docker Compose.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Docker Network (substrate-net)           │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  Substrate   │  │   Registry   │  │   Auth Hub   │      │
│  │   Hub        │  │              │  │              │      │
│  │  Port 4444   │  │  Port 4445   │  │  Port 4446   │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│         │                  │                  │             │
└─────────┼──────────────────┼──────────────────┼─────────────┘
          │                  │                  │
          │                  │                  └─── ./secrets/
          │                  └───────────────────── registry-data/
          └──────────────────────────────────────── (in-memory)
```

All services are based on `substrate-base` image containing synapse.

## Quick Start

### 1. Build the Base Image

First, build the base image with synapse:

```bash
docker build -f Dockerfile.base -t ghcr.io/hypermemetic/substrate-base:latest .
```

### 2. Create Secrets Directory

Create a directory for auth-hub secrets:

```bash
mkdir -p secrets
```

Optionally, create an initial secrets file:

```bash
cat > secrets/secrets.yaml << 'EOF'
secrets:
  example/demo/token:
    value: "demo_secret_value"
    created_at: "2026-01-28T00:00:00Z"
    updated_at: "2026-01-28T00:00:00Z"
EOF
```

### 3. Start All Services

```bash
docker-compose up -d
```

### 4. Check Service Health

```bash
docker-compose ps
```

Expected output:
```
NAME        IMAGE               STATUS         PORTS
substrate   substrate-hub       Up (healthy)   0.0.0.0:4444->4444/tcp
registry    registry            Up (healthy)   0.0.0.0:4445->4445/tcp
auth-hub    auth-hub            Up (healthy)   0.0.0.0:4446->4446/tcp
```

### 5. View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f substrate
docker-compose logs -f registry
docker-compose logs -f auth-hub
```

## Usage

### Using Synapse CLI

Since synapse is installed in all containers, you can use it from within any container:

```bash
# Execute synapse from substrate container
docker-compose exec substrate synapse -P 4444 substrate health check

# Execute synapse from auth-hub container
docker-compose exec auth-hub synapse -P 4446 secrets auth list_secrets --prefix example/
```

### From Host (if synapse installed)

```bash
# Substrate health check
synapse -H localhost -P 4444 substrate health check

# List all substrate activations
synapse -H localhost -P 4444 substrate

# Auth hub - set a secret
synapse -H localhost -P 4446 secrets auth set_secret \
  --secret-key github/myuser/token \
  --value ghp_xxxxxxxxxxxxx

# Auth hub - get a secret
synapse -H localhost -P 4446 secrets auth get_secret \
  --secret-key github/myuser/token

# Auth hub - list secrets
synapse -H localhost -P 4446 secrets auth list_secrets --prefix github/

# Registry - list backends
synapse -H localhost -P 4445 registry registry list
```

### Using Raw JSON-RPC (websocat/wscat)

```bash
# Install websocat if needed
# brew install websocat  # macOS
# cargo install websocat  # via Rust

# Connect to substrate
echo '{"jsonrpc":"2.0","id":1,"method":"plexus.health.check","params":{}}' | \
  websocat ws://localhost:4444

# Connect to auth-hub
echo '{"jsonrpc":"2.0","id":1,"method":"secrets.auth.list_secrets","params":{"prefix":""}}' | \
  websocat ws://localhost:4446
```

## Managing Secrets

Secrets are persisted in the `./secrets/` directory on the host and mounted into the auth-hub container.

### Access Secrets File

```bash
# View secrets
cat secrets/secrets.yaml

# Edit secrets manually (requires restart)
vim secrets/secrets.yaml
docker-compose restart auth-hub
```

### Backup Secrets

```bash
# Create backup
cp secrets/secrets.yaml secrets/secrets.yaml.backup

# Or with timestamp
cp secrets/secrets.yaml secrets/secrets.$(date +%Y%m%d_%H%M%S).yaml
```

## Service Management

### Start Services

```bash
docker-compose up -d
```

### Stop Services

```bash
docker-compose down
```

### Restart a Service

```bash
docker-compose restart substrate
docker-compose restart registry
docker-compose restart auth-hub
```

### Rebuild After Code Changes

```bash
# Rebuild all services
docker-compose build

# Rebuild specific service
docker-compose build substrate

# Rebuild and restart
docker-compose up -d --build
```

### Scale Services (if needed)

```bash
# Note: Current setup is single-instance
# To scale, you'd need to adjust ports and networking
docker-compose up -d --scale substrate=2
```

## Volumes

### Registry Volumes

- `registry-config`: Configuration files for registry
- `registry-data`: SQLite database for backend registrations

### List Volumes

```bash
docker volume ls | grep substrate
```

### Inspect Volume

```bash
docker volume inspect workspace_registry-data
```

### Backup Registry Data

```bash
docker run --rm \
  -v workspace_registry-data:/data \
  -v $(pwd):/backup \
  debian:bookworm-slim \
  tar czf /backup/registry-backup.tar.gz -C /data .
```

### Restore Registry Data

```bash
docker run --rm \
  -v workspace_registry-data:/data \
  -v $(pwd):/backup \
  debian:bookworm-slim \
  tar xzf /backup/registry-backup.tar.gz -C /data
```

## Networking

All services communicate on the `substrate-net` bridge network:

```bash
# Inspect network
docker network inspect workspace_substrate-net

# Test connectivity between services
docker-compose exec substrate nc -zv registry 4445
docker-compose exec substrate nc -zv auth-hub 4446
```

## Troubleshooting

### Service Won't Start

```bash
# Check logs
docker-compose logs substrate

# Check container status
docker-compose ps substrate

# Rebuild image
docker-compose build substrate
docker-compose up -d substrate
```

### Connection Refused

```bash
# Check if service is listening
docker-compose exec substrate ss -tlnp

# Check health
docker-compose exec substrate nc -zv localhost 4444
```

### Secrets Not Loading

```bash
# Check volume mount
docker-compose exec auth-hub ls -la /config/auth-hub/

# Check HOME environment
docker-compose exec auth-hub env | grep HOME

# Check file permissions
ls -la secrets/
```

### Clean Start

```bash
# Stop and remove everything
docker-compose down -v

# Remove all images
docker-compose down --rmi all

# Rebuild from scratch
docker-compose build --no-cache
docker-compose up -d
```

## Production Considerations

### Environment Variables

Create a `.env` file for production settings:

```bash
cat > .env << 'EOF'
# Logging
RUST_LOG=info

# Ports (can be customized)
SUBSTRATE_PORT=4444
REGISTRY_PORT=4445
AUTH_HUB_PORT=4446

# Resource limits
SUBSTRATE_MEMORY=512m
REGISTRY_MEMORY=256m
AUTH_HUB_MEMORY=256m
EOF
```

Update `docker-compose.yml` to use these:

```yaml
services:
  substrate:
    ports:
      - "${SUBSTRATE_PORT:-4444}:4444"
    deploy:
      resources:
        limits:
          memory: ${SUBSTRATE_MEMORY:-512m}
```

### Security

1. **Secrets**: Never commit `secrets/secrets.yaml` to git
   ```bash
   echo "secrets/" >> .gitignore
   ```

2. **Network Isolation**: Use Docker networks to isolate services

3. **TLS/SSL**: Add reverse proxy (nginx/traefik) for HTTPS

4. **Read-Only Filesystems**: Add to docker-compose.yml:
   ```yaml
   read_only: true
   tmpfs:
     - /tmp
   ```

### Monitoring

Add health check endpoints and monitoring:

```bash
# Health check script
while true; do
  for port in 4444 4445 4446; do
    nc -z localhost $port && echo "Port $port: OK" || echo "Port $port: FAIL"
  done
  sleep 30
done
```

## Advanced Usage

### Development with Live Reload

Mount source directories for development:

```yaml
volumes:
  - ./substrate/src:/workspace/substrate/src:ro
```

### Custom Configuration

Create service-specific configs:

```bash
# Registry config
mkdir -p registry-config
cat > registry-config/backends.toml << 'EOF'
[[backend]]
name = "substrate"
host = "substrate"
port = 4444
protocol = "ws"
description = "Main substrate hub"
EOF
```

Mount in docker-compose.yml:

```yaml
services:
  registry:
    volumes:
      - ./registry-config:/config:ro
```

## License

See individual package licenses:
- substrate: AGPL-3.0-only
- registry: AGPL-3.0-only
- auth-hub: MIT
