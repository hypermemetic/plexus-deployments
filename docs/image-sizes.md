# Image Size Optimization

## Size Comparison

### Old Approach (Debian + Synapse base)
```
Base image:      ~500MB  (Debian + GHC + Cabal + Synapse)
Substrate:       ~600MB  (Base + 35MB binary)
Registry:        ~550MB  (Base + 13MB binary)
Auth-hub:        ~550MB  (Base + 10MB binary)
────────────────────────
Total:          ~2.2GB   ❌ WAY TOO BIG
```

### New Approach (Alpine + Binary only)
```
Substrate:        ~40MB  (Alpine + 35MB binary)
Registry:         ~18MB  (Alpine + 13MB binary)
Auth-hub:         ~15MB  (Alpine + 10MB binary)
Synapse (opt):   ~100MB  (Only if needed in container)
────────────────────────
Total:            ~73MB   ✅ 30x SMALLER!
```

## Why Were They So Large?

### Problem 1: Unnecessary Base Image
❌ **Old way**: Every service based on Haskell+Synapse image
```dockerfile
FROM synapse-base:latest  # 500MB with GHC/Cabal
COPY binary /usr/local/bin/
```

✅ **New way**: Only copy what's needed
```dockerfile
FROM alpine:3.19          # 5MB
COPY binary /usr/local/bin/
```

### Problem 2: Wrong Base Distro
- **Debian Bookworm Slim**: ~80MB
- **Alpine Linux**: ~5MB
- **Distroless**: ~2MB (even better!)

### Problem 3: Synapse in Every Image
Services don't need synapse inside them! Synapse is a **client tool** for operators.

Use synapse from:
- ✅ Your host machine
- ✅ Separate synapse container (when needed)
- ❌ Not in every service image

### Problem 4: Build Dependencies Left In
❌ **Old multi-stage** (but still wrong):
```dockerfile
FROM rust:bookworm AS builder
# ... build ...
FROM debian:bookworm-slim AS runtime  # Still 80MB
FROM synapse-base:latest              # Even worse: 500MB!
```

✅ **Proper multi-stage**:
```dockerfile
FROM rust:alpine AS builder
# ... build ...
FROM alpine:3.19 AS runtime           # Only 5MB
# Or even better:
FROM scratch                          # 0MB (static binary)
```

## Optimization Techniques

### 1. Use Alpine Linux
```dockerfile
FROM alpine:3.19  # 5MB vs debian:bookworm-slim 80MB
```

### 2. Strip Binaries
```dockerfile
RUN strip target/release/binary  # Remove debug symbols
```

### 3. Multi-stage Builds
```dockerfile
FROM rust:alpine AS builder
# Build here

FROM alpine:3.19
COPY --from=builder /build/binary /usr/local/bin/
# Only the binary, nothing else!
```

### 4. Minimal Runtime Dependencies
```dockerfile
# Only what's absolutely needed
RUN apk add --no-cache ca-certificates libgcc
```

### 5. Use Distroless (Even Better)
```dockerfile
FROM gcr.io/distroless/static:nonroot  # ~2MB
COPY --from=builder /build/binary /
```

## Current Dockerfiles

### Substrate (~40MB)
```
Alpine base:                    5MB
Substrate binary (stripped):   35MB
Runtime deps (ca-certs, etc):   <1MB
────────────────────────────────
Total:                         ~40MB
```

### Registry (~18MB)
```
Alpine base:                    5MB
Registry binary (stripped):    13MB
Runtime deps:                  <1MB
────────────────────────────────
Total:                         ~18MB
```

### Auth-hub (~15MB)
```
Alpine base:                    5MB
Auth-hub binary (stripped):    10MB
Runtime deps:                  <1MB
────────────────────────────────
Total:                         ~15MB
```

## Further Optimizations

### Use Distroless (Future)
Could get down to ~40MB total for all three services!

```dockerfile
FROM gcr.io/distroless/cc-debian12  # ~2MB
# or
FROM scratch  # 0MB (for static binaries)
```

### Static Linking
Build fully static binaries:
```toml
# Cargo.toml
[profile.release]
lto = true
codegen-units = 1
panic = "abort"
strip = true
```

```bash
cargo build --release --target x86_64-unknown-linux-musl
```

Could reduce substrate from 35MB to ~25MB.

### UPX Compression (Risky)
Compress the binary:
```bash
upx --best --lzma substrate
# Can reduce by 50-70%, but slower startup
```

## Why Not Go Even Smaller?

**We could**, but there are tradeoffs:

### Distroless Pros:
- ✅ ~2MB instead of 5MB
- ✅ More secure (no shell, no package manager)
- ❌ Harder to debug (no shell access)

### Static Linking Pros:
- ✅ Smaller binaries
- ✅ No runtime dependencies
- ❌ Longer compile times
- ❌ Larger binary size than dynamic

### Current Choice: Alpine
Good balance of:
- Small size (~5MB base)
- Easy debugging (has shell)
- Wide compatibility
- Fast builds

## Recommended Setup

### For Development
Use Alpine with shell for easy debugging:
```dockerfile
FROM alpine:3.19
RUN apk add --no-cache bash curl
# Easy to docker exec and debug
```

### For Production
Use Distroless for security:
```dockerfile
FROM gcr.io/distroless/static:nonroot
# No shell = more secure
```

## Build Size vs Download Size

Docker uses layers, so:
- **Build size**: All layers uncompressed
- **Download size**: Compressed, shared layers

With Alpine:
- Substrate image: ~40MB build, ~20MB download (compressed)
- Registry image: ~18MB build, ~10MB download
- Auth-hub image: ~15MB build, ~8MB download

## Synapse Container (Optional)

If you really need synapse in a container:

```dockerfile
# Multi-stage with only the binary
FROM haskell:9.6-alpine AS builder
# ... build synapse ...

FROM alpine:3.19
RUN apk add --no-cache gmp libffi
COPY --from=builder /root/.local/bin/synapse /usr/local/bin/
# Result: ~100MB (vs 500MB before)
```

But better to:
1. Install synapse on host: `cabal install synapse`
2. Use it from there to interact with containers
3. Don't need it IN containers

## Summary

| Optimization | Savings | Tradeoff |
|--------------|---------|----------|
| Alpine vs Debian | ~75MB per image | None |
| Remove Synapse base | ~400MB per image | None (it's not needed) |
| Strip binaries | ~10-20% | None (debug symbols not needed) |
| Multi-stage properly | Depends | None |
| Static linking | ~20-30% | Longer builds |
| Distroless | ~3MB | Harder debugging |
| UPX compression | ~50-70% | Slower startup |

**Current approach**: Alpine + stripped binaries = 30x size reduction with zero downsides!
