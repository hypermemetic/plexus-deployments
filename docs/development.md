# Development Guide

Guide for developing and contributing to substrate-deployments.

## Setup for Local Development

### 1. Clone Required Repositories

The deployments repo references other repos. Clone them alongside:

```bash
mkdir -p ~/dev/substrate-ecosystem
cd ~/dev/substrate-ecosystem

# Clone this repo
git clone <url> substrate-deployments

# Clone service repos
git clone <url> substrate
git clone <url> registry
git clone <url> auth-hub
git clone <url> synapse

# Clone dependencies
git clone <url> hub-core
git clone <url> hub-macro
git clone <url> hub-transport
```

Your structure should look like:
```
~/dev/substrate-ecosystem/
├── substrate-deployments/    # This repo
├── substrate/                 # Main hub
├── registry/                  # Registry service
├── auth-hub/                  # Auth service
├── synapse/                   # CLI tool
├── hub-core/                  # Shared library
├── hub-macro/                 # Shared library
└── hub-transport/             # Shared library
```

### 2. Configure Environment

```bash
cd substrate-deployments/standard
cp .env.example .env
```

Edit `.env` to point to your local repos:
```bash
SUBSTRATE_PATH=../../substrate
REGISTRY_PATH=../../registry
AUTH_HUB_PATH=../../auth-hub
# ... etc
```

### 3. Build and Run

```bash
# Build everything
make build-base
make build

# Start services
make up

# Watch logs
make logs
```

## Making Changes

### Adding a New Architecture

1. Create directory:
   ```bash
   mkdir custom/my-architecture
   ```

2. Add `docker-compose.yml`:
   ```yaml
   version: '3.8'
   services:
     # Define your services
   ```

3. Add `README.md` documenting the use case

4. Test it:
   ```bash
   cd custom/my-architecture
   docker-compose up -d
   ```

### Modifying Dockerfiles

Dockerfiles live in the individual service repos, not here.

To modify how a service is built:
1. Edit `<service>/Dockerfile` in that repo
2. Rebuild: `docker-compose build <service>`
3. Test changes
4. Commit to service repo

### Updating Base Image

The base image (`base/Dockerfile.synapse`) can be updated here:

```bash
cd base
docker build -f Dockerfile.synapse -t substrate-base:dev .
```

Update references in docker-compose files:
```yaml
services:
  substrate:
    build:
      context: ...
    image: substrate-base:dev
```

## Testing

### Integration Tests

Test a full stack:
```bash
cd standard
make test

# Or manually
docker-compose up -d
docker-compose exec substrate synapse -P 4444 substrate health check
docker-compose exec auth-hub synapse -P 4446 secrets auth list_secrets --prefix ""
```

### Load Testing

Test under load:
```bash
# Install k6 or similar
k6 run scripts/load-test.js
```

### Resource Testing

Verify resource limits:
```bash
# Monitor resources
docker stats

# Check limits are enforced
docker inspect <container> | grep -A10 Resources
```

## Debugging

### View Logs

```bash
# All services
make logs

# Specific service
docker-compose logs -f substrate

# With timestamps
docker-compose logs -f --timestamps substrate
```

### Shell Access

```bash
# Get shell in container
make shell-substrate
make shell-registry
make shell-auth

# Or directly
docker-compose exec substrate bash
```

### Network Debugging

```bash
# Test connectivity
docker-compose exec substrate nc -zv registry 4445

# Inspect network
docker network inspect substrate-deployments_substrate-net
```

### Build Debugging

```bash
# See build output
docker-compose build --progress=plain substrate

# No cache rebuild
docker-compose build --no-cache substrate
```

## Performance Optimization

### Build Optimization

1. **Use BuildKit:**
   ```bash
   export DOCKER_BUILDKIT=1
   ```

2. **Multi-stage builds:**
   Already implemented in Dockerfiles

3. **Layer caching:**
   Copy dependency manifests before source code

### Runtime Optimization

1. **Resource limits:**
   ```yaml
   deploy:
     resources:
       limits:
         memory: 512m
   ```

2. **Restart policies:**
   ```yaml
   restart: unless-stopped
   ```

3. **Health checks:**
   Keep lightweight, adjust intervals

## CI/CD Integration

### GitHub Actions

Example workflow:
```yaml
name: Build and Test

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Build base image
        run: make build-base

      - name: Build services
        run: make build

      - name: Start services
        run: make up

      - name: Run tests
        run: make test
```

### Publishing Images

Build and push to registry:
```bash
# Tag
docker tag substrate-hub:latest ghcr.io/org/substrate-hub:latest

# Push
docker push ghcr.io/org/substrate-hub:latest
```

Update docker-compose to use published images:
```yaml
services:
  substrate:
    image: ghcr.io/org/substrate-hub:latest
    # Remove build section
```

## Best Practices

### 1. Keep It Portable

- Use relative paths in `.env`
- Don't hardcode absolute paths
- Document all environment variables

### 2. Version Control

- Commit `.env.example`, not `.env`
- Use `.gitignore` for secrets
- Tag releases

### 3. Documentation

- Update README for new architectures
- Document environment variables
- Add architecture diagrams

### 4. Security

- Never commit secrets
- Use .env for sensitive config
- Review exposed ports

### 5. Testing

- Test before committing
- Verify on clean checkout
- Check resource usage

## Common Issues

### "Cannot find repository"

Set paths in `.env`:
```bash
SUBSTRATE_PATH=/absolute/path/to/substrate
```

### "Permission denied"

Fix file permissions:
```bash
chmod +x docker-quick-start.sh
sudo chown -R $USER:$USER .
```

### "Port already in use"

Change ports in `.env`:
```bash
SUBSTRATE_PORT=5444
```

### "Build context too large"

Add `.dockerignore` to service repos:
```
target/
.git/
docs/
```

## Contributing

1. Fork the repo
2. Create feature branch: `git checkout -b feature/my-architecture`
3. Make changes
4. Test thoroughly
5. Submit PR with:
   - Description of architecture
   - Use case
   - Testing performed
   - Documentation updates

## Getting Help

- Check docs/ directory
- Review examples in custom/examples/
- Open an issue on GitHub
- Check service-specific repos for issues
