# Architecture Guide

This document describes the various deployment architectures available in substrate-deployments.

## Overview

Substrate Deployments supports multiple architecture patterns, each optimized for different use cases:

```
substrate-deployments/
├── standard/        # Full production stack
├── minimal/         # Just substrate hub
└── custom/          # Custom architectures
    └── examples/
        ├── edge-stack.yml       # Low-resource edge deployment
        ├── dev-stack.yml        # Development with hot-reload
        ├── ha-stack.yml         # High availability (future)
        └── multi-region.yml     # Multi-region (future)
```

## Standard Stack

**Use Case:** Production deployments with full feature set

**Services:**
- Substrate Hub (4444) - Main plugin hub
- Registry (4445) - Backend discovery service
- Auth Hub (4446) - Secret management

**Resource Requirements:**
- Memory: ~1GB
- CPU: 2 cores recommended
- Disk: ~2GB for images + data volumes

**Architecture:**
```
┌─────────────────────────────────────────────────────┐
│            Docker Network (substrate-net)           │
│                                                      │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐       │
│  │Substrate │   │ Registry │   │ Auth Hub │       │
│  │  :4444   │   │  :4445   │   │  :4446   │       │
│  └────┬─────┘   └────┬─────┘   └────┬─────┘       │
│       │              │              │              │
└───────┼──────────────┼──────────────┼──────────────┘
        │              │              │
        │              │              └── ./secrets/
        │              └─── registry-data (volume)
        └─── (ephemeral)
```

**When to Use:**
- Production deployments
- Need all services
- Secret management required
- Backend registration needed

## Minimal Stack

**Use Case:** Development, testing, minimal deployments

**Services:**
- Substrate Hub (4444) only

**Resource Requirements:**
- Memory: ~300MB
- CPU: 1 core
- Disk: ~500MB

**Architecture:**
```
┌─────────────────────────┐
│     substrate-net        │
│                          │
│   ┌──────────────┐      │
│   │  Substrate   │      │
│   │    :4444     │      │
│   └──────────────┘      │
└─────────────────────────┘
```

**When to Use:**
- Local development
- Testing substrate features
- Don't need registry or auth
- Minimal resource usage

## Edge Stack

**Use Case:** Resource-constrained environments (IoT, edge devices)

**Services:**
- Substrate Hub (limited) - Essential activations only
- Auth Hub - Lightweight secret management

**Resource Requirements:**
- Memory: ~400MB
- CPU: 0.75 cores
- Disk: ~300MB

**Optimizations:**
- Reduced logging (WARN level)
- Memory limits enforced
- CPU quotas
- Minimal container images
- No registry (static config)

**When to Use:**
- Raspberry Pi deployments
- Edge computing nodes
- IoT gateways
- Limited resources

## Development Stack

**Use Case:** Active development with hot-reload

**Services:**
- All standard services
- Source code mounted as volumes
- Debug ports exposed
- Development tools included

**Features:**
- Hot-reload (via volume mounts)
- Debug logging (RUST_LOG=debug)
- Stack traces (RUST_BACKTRACE=1)
- Debug ports (9229+)
- Development tools (websocat, etc.)

**When to Use:**
- Active feature development
- Debugging issues
- Testing changes quickly
- Learning the system

## Custom Architectures

Create your own by:

1. **Copy an example:**
   ```bash
   cp custom/examples/edge-stack.yml custom/my-stack.yml
   ```

2. **Modify services:**
   - Add/remove services
   - Change resource limits
   - Adjust environment variables
   - Configure volumes

3. **Deploy:**
   ```bash
   cd custom
   docker-compose -f my-stack.yml up -d
   ```

### Example: Analytics Stack

Add analytics services:
```yaml
services:
  substrate:
    # ... standard config ...

  prometheus:
    image: prom/prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml

  grafana:
    image: grafana/grafana
    ports:
      - "3000:3000"
```

## Comparison Matrix

| Feature | Standard | Minimal | Edge | Dev |
|---------|----------|---------|------|-----|
| Substrate Hub | ✓ | ✓ | ✓ (limited) | ✓ |
| Registry | ✓ | ✗ | ✗ | ✓ |
| Auth Hub | ✓ | ✗ | ✓ | ✓ |
| Memory | ~1GB | ~300MB | ~400MB | ~1.5GB |
| Hot-reload | ✗ | ✗ | ✗ | ✓ |
| Debug Tools | ✗ | ✗ | ✗ | ✓ |
| Production Ready | ✓ | ✗ | ✓ | ✗ |

## Networking

All architectures use a bridge network (`substrate-net`) for service communication.

**Internal DNS:**
- Services can reach each other by container name
- Example: `ws://substrate:4444` from registry container

**External Access:**
- Services exposed via port mappings
- Default: localhost only
- Production: Use reverse proxy (nginx/traefik)

## Volumes and Persistence

### Standard Stack
- `registry-config` - Registry configuration
- `registry-data` - Registry SQLite database
- `./secrets` - Auth Hub secrets (host mount)

### Minimal Stack
- None (ephemeral)

### Edge Stack
- `./secrets` - Auth Hub secrets only

### Dev Stack
- Source code mounted read-only
- Logs mounted for inspection

## Security Considerations

### Standard/Production
- Use secrets management (auth-hub)
- Network isolation
- Read-only filesystems where possible
- Non-root users in containers

### Development
- Relaxed security for convenience
- Debug ports exposed
- Source code mounted
- **DO NOT** use in production

### Edge
- Minimal attack surface
- Resource limits prevent DoS
- Secrets in encrypted volume recommended

## Scaling Patterns

### Horizontal Scaling

**Substrate Hub:**
```yaml
services:
  substrate:
    deploy:
      replicas: 3
```

**Load Balancing:**
Add nginx/haproxy to distribute requests.

### Vertical Scaling

Adjust resource limits:
```yaml
deploy:
  resources:
    limits:
      memory: 2g
      cpus: '2.0'
```

## Migration Paths

### Development → Standard
1. Remove debug configurations
2. Remove volume mounts
3. Set RUST_LOG=info
4. Add auth-hub if needed

### Standard → Edge
1. Remove registry service
2. Add resource limits
3. Reduce logging
4. Static configuration

### Minimal → Standard
1. Add registry service
2. Add auth-hub service
3. Configure volumes
4. Update network

## Future Architectures

Planned additions:
- **HA Stack** - High availability with replication
- **Multi-Region** - Cross-region deployment
- **Kubernetes** - K8s manifests
- **Serverless** - Cloud function deployments
