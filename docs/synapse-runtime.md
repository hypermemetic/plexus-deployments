# Adding Synapse at Runtime

Several strategies for making synapse available without bloating service images.

## Strategy 1: Shared Volume (Recommended)

Build synapse once, share the binary with all containers via a volume.

### How It Works

```yaml
# docker-compose.yml
volumes:
  synapse-bin:  # Shared volume for synapse binary

services:
  # One-time builder that puts synapse in the volume
  synapse-builder:
    build:
      context: ${REPO_ROOT:-../..}
      dockerfile: substrate-deployments/base/Dockerfile.synapse
    volumes:
      - synapse-bin:/synapse-output
    command: sh -c "cp /usr/local/bin/synapse /synapse-output/"
    profiles:
      - init

  # Services mount the synapse binary
  substrate:
    volumes:
      - synapse-bin:/opt/synapse:ro
    environment:
      - PATH=/opt/synapse:/usr/local/bin:/usr/bin:/bin
```

**Usage:**
```bash
# First time: build synapse
docker-compose --profile init up synapse-builder

# Start services (they now have synapse)
docker-compose up -d

# Use synapse from any container
docker-compose exec substrate synapse -P 4444 plexus health check
```

**Pros:**
- ✅ Built once, shared everywhere
- ✅ No image bloat
- ✅ Persists across restarts
- ✅ Easy to update (rebuild synapse-builder)

**Cons:**
- ⚠️ Extra step on first run

## Strategy 2: Sidecar Container

Dedicated synapse container that services can communicate with.

### How It Works

```yaml
services:
  synapse:
    build:
      context: ${REPO_ROOT:-../..}
      dockerfile: substrate-deployments/base/Dockerfile.synapse
    container_name: synapse-tools
    networks:
      - substrate-net
    stdin_open: true
    tty: true
    command: tail -f /dev/null  # Keep running
```

**Usage:**
```bash
# Synapse runs alongside services
docker-compose up -d

# Execute synapse commands
docker-compose exec synapse synapse -P 4444 plexus health check
docker-compose exec synapse synapse -P 4446 secrets auth list_secrets
```

**Pros:**
- ✅ Always available
- ✅ No image bloat
- ✅ Easy to use

**Cons:**
- ⚠️ Extra container running (~100MB)

## Strategy 3: Mount from Host

Mount your host-installed synapse into containers.

### How It Works

```yaml
# docker-compose.override.yml (local development)
services:
  substrate:
    volumes:
      - /usr/local/bin/synapse:/usr/local/bin/synapse:ro
      - ~/.cabal:/root/.cabal:ro  # If synapse needs libs
```

**Usage:**
```bash
# Install synapse on host
cabal install synapse

# Find synapse location
which synapse  # /usr/local/bin/synapse or ~/.cabal/bin/synapse

# Update docker-compose.override.yml with that path
# Start services
docker-compose up -d

# Synapse now available in containers
docker-compose exec substrate synapse --version
```

**Pros:**
- ✅ Zero image bloat
- ✅ Use your existing synapse installation
- ✅ Easy updates (update on host)

**Cons:**
- ⚠️ Host dependency
- ⚠️ May need library mounts
- ⚠️ Linux-only (binary compatibility)

## Strategy 4: Download on Startup

Download synapse binary on container startup.

### How It Works

```dockerfile
# Add to service Dockerfiles
FROM alpine:3.19

# ... existing setup ...

# Add startup script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["substrate", "--port", "4444"]
```

```bash
#!/bin/sh
# entrypoint.sh

# Download synapse if not present
if [ ! -f /usr/local/bin/synapse ]; then
    echo "Downloading synapse..."
    wget -O /usr/local/bin/synapse https://github.com/.../synapse
    chmod +x /usr/local/bin/synapse
fi

# Run the actual service
exec "$@"
```

**Pros:**
- ✅ No image bloat
- ✅ Automatic download

**Cons:**
- ⚠️ Slower startup
- ⚠️ Network dependency
- ⚠️ Need a release binary URL

## Strategy 5: Multi-stage with Optional Copy

Build synapse in Dockerfile but only copy it when needed.

### How It Works

```dockerfile
FROM haskell:9.6-alpine AS synapse-builder
WORKDIR /build
COPY synapse /build/synapse
RUN cd synapse && cabal install

FROM rust:alpine AS service-builder
# ... build service ...

FROM alpine:3.19
ARG INCLUDE_SYNAPSE=false

COPY --from=service-builder /build/target/release/substrate /usr/local/bin/

# Conditionally include synapse
RUN if [ "$INCLUDE_SYNAPSE" = "true" ]; then \
      COPY --from=synapse-builder /root/.local/bin/synapse /usr/local/bin/; \
    fi
```

**Usage:**
```bash
# Build without synapse (default, small)
docker build -t substrate:latest .

# Build with synapse (larger)
docker build --build-arg INCLUDE_SYNAPSE=true -t substrate:with-synapse .
```

**Pros:**
- ✅ Flexible
- ✅ Same Dockerfile for both cases

**Cons:**
- ⚠️ Still builds synapse every time
- ⚠️ More complex

## Recommended Approach

### For Development: Strategy 3 (Mount from Host)

```yaml
# docker-compose.override.yml
services:
  substrate:
    volumes:
      - ${SYNAPSE_BIN:-~/.cabal/bin/synapse}:/usr/local/bin/synapse:ro
  registry:
    volumes:
      - ${SYNAPSE_BIN:-~/.cabal/bin/synapse}:/usr/local/bin/synapse:ro
  auth-hub:
    volumes:
      - ${SYNAPSE_BIN:-~/.cabal/bin/synapse}:/usr/local/bin/synapse:ro
```

```bash
# .env
SYNAPSE_BIN=/home/user/.cabal/bin/synapse
```

### For Production: Strategy 1 (Shared Volume)

```yaml
volumes:
  synapse-bin:

services:
  synapse-init:
    build:
      dockerfile: base/Dockerfile.synapse
    volumes:
      - synapse-bin:/output
    command: cp /usr/local/bin/synapse /output/
    restart: "no"

  substrate:
    volumes:
      - synapse-bin:/opt/synapse:ro
    environment:
      PATH: /opt/synapse:/usr/local/bin:/usr/bin:/bin
    depends_on:
      synapse-init:
        condition: service_completed_successfully
```

### For CI/CD: Strategy 2 (Sidecar)

```yaml
services:
  synapse:
    image: synapse:latest
    container_name: synapse-tools

  # Test using synapse sidecar
  test:
    image: alpine
    depends_on: [substrate, synapse]
    command: docker exec synapse synapse -P 4444 plexus health check
```

## Comparison

| Strategy | Image Size | Complexity | Best For |
|----------|-----------|------------|----------|
| Shared Volume | Small (0MB) | Medium | Production |
| Sidecar | Small (0MB) | Low | Always-on use |
| Mount from Host | Small (0MB) | Low | Development |
| Download on Startup | Small (0MB) | Medium | One-off scripts |
| Multi-stage Optional | Variable | High | Flexibility |

## Implementation Example

See `standard/docker-compose.synapse-shared.yml` for a complete working example.
