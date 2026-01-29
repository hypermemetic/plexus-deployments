# Binary Size Optimization

## Current Sizes (Unoptimized)

```
substrate: 35MB
registry:  13MB
auth-hub:  10MB
────────────
Total:     58MB
```

## Why Are They So Large?

### 1. No Cargo Release Optimizations

**Current:** Default release profile
```toml
# No custom [profile.release] configuration
# Uses Cargo defaults which prioritize compile speed over size
```

**Problem:**
- ❌ No Link Time Optimization (LTO)
- ❌ No symbol stripping in Cargo
- ❌ Multiple codegen units (faster build, larger binary)
- ❌ Includes panic unwinding (adds code)

### 2. Heavy Dependencies

**Substrate includes:**
```
- tokio (full runtime)              ~2-3MB
- jsonrpsee (JSON-RPC)              ~1-2MB
- sqlx (database)                   ~2-3MB
- serde + serde_json                ~1MB
- axum (web framework)              ~1-2MB
- hub ecosystem (hub-core, etc)     ~5-10MB
- Multiple activations              ~10-15MB
  - cone (LLM)
  - arbor (tree storage)
  - jsexec (V8 JavaScript)
  - hyperforge (git ops)
  - claudecode
  - etc.
```

**Why each activation adds size:**
- Each has its own logic and dependencies
- Substrate bundles 13 activations!
- V8 JavaScript engine (jsexec) is particularly heavy

### 3. Rust Runtime and Standard Library

```
- Core Rust runtime:     ~500KB
- Panic handling:        ~200KB
- Format machinery:      ~300KB
- Collection types:      ~500KB
```

### 4. Debug Information (Even After `strip`)

The `strip` command only removes basic symbols. Cargo can do better.

## Optimization Strategies

### Strategy 1: Optimize Cargo Profile (Easy - 30% reduction)

Add to each `Cargo.toml`:

```toml
[profile.release]
# Enable Link Time Optimization
lto = true              # or "fat" for max optimization
# Optimize for size
opt-level = "z"         # "z" for size, "s" also works
# Single codegen unit for better optimization
codegen-units = 1
# Remove panic unwinding
panic = "abort"
# Strip symbols in Cargo (better than external strip)
strip = true
```

**Expected result:**
```
substrate: 35MB → 24MB  (31% reduction)
registry:  13MB → 9MB   (31% reduction)
auth-hub:  10MB → 7MB   (30% reduction)
────────────────────────
Total:     58MB → 40MB  (31% reduction)
```

### Strategy 2: Selective Feature Flags (Medium - 40% reduction)

Only enable needed features:

```toml
# Bad (current)
tokio = { version = "1.0", features = ["full"] }

# Good (optimized)
tokio = { version = "1.0", features = ["rt-multi-thread", "macros", "net"] }
```

**Other heavy dependencies:**

```toml
# Only needed features
sqlx = { version = "0.6", features = ["runtime-tokio-rustls", "sqlite"] }
# Remove: chrono, uuid features if not needed

jsonrpsee = { version = "0.26", features = ["server", "macros"] }
# Remove: client features if not needed in binary
```

**Expected additional reduction:** 5-10MB

### Strategy 3: Split Activations (Advanced - 50% reduction)

Instead of one big binary, make activations optional:

```toml
[features]
default = ["minimal"]
minimal = ["health", "echo"]
full = ["cone", "arbor", "jsexec", "hyperforge", "claudecode", ...]

[dependencies]
jsexec = { path = "../jsexec", optional = true }
```

Build minimal version:
```bash
cargo build --release --no-default-features --features minimal
```

**Result:**
```
substrate-minimal: 35MB → 8MB   (77% reduction!)
substrate-full:    35MB → 30MB  (still optimized)
```

### Strategy 4: Compression (Medium - 50-70% reduction)

Use UPX to compress the binary:

```bash
cargo build --release
upx --best --lzma target/release/substrate
```

**Tradeoffs:**
- ✅ Much smaller (17-25MB)
- ❌ Slower startup (~100ms)
- ❌ More memory usage (decompression)
- ⚠️ May break some binaries

### Strategy 5: Dynamic Linking (Advanced - Variable)

Link to system libraries instead of static:

```bash
cargo build --release --config 'target.x86_64-unknown-linux-gnu.rustflags=["-C", "prefer-dynamic"]'
```

**Tradeoffs:**
- ✅ Smaller binaries
- ❌ Requires libraries on target system
- ❌ Less portable

### Strategy 6: Optimize Each Activation

**Heavy activations:**

**jsexec** (~5-8MB) - JavaScript execution via V8
- Consider: deno_core is lighter than full V8
- Or: Make it an optional feature
- Or: Split into separate binary

**sqlx** (~3-5MB) - Database
- Only used by: arbor, changelog, cone
- Consider: Separate these into a "storage" binary
- Or: Use rusqlite (lighter)

**cllient** (LLM client) - Used by cone, claudecode
- Heavy dependency
- Consider: Make optional or split

## Recommended Configuration

### For substrate/Cargo.toml

```toml
[profile.release]
opt-level = "z"        # Optimize for size
lto = true             # Link Time Optimization
codegen-units = 1      # Better optimization
panic = "abort"        # Remove unwinding
strip = true           # Remove symbols

[profile.release.package."*"]
opt-level = "z"        # Apply to all dependencies
strip = true

# Optimize heavy dependencies
[dependencies]
tokio = { version = "1.0", features = [
    "rt-multi-thread",
    "macros",
    "net",
    "sync",
    "time"
] }
# Remove: "full", "io-util", "io-std", "fs", "process"

sqlx = { version = "0.6", features = [
    "runtime-tokio-rustls",
    "sqlite"
] }
# Remove: "chrono", "uuid" if possible

jsonrpsee = { version = "0.26", features = [
    "server",
    "macros"
] }
# Remove: "client", "ws-client" from server binaries
```

### For registry/Cargo.toml

```toml
[profile.release]
opt-level = "z"
lto = true
codegen-units = 1
panic = "abort"
strip = true

[dependencies]
# Minimal features
tokio = { version = "1.0", features = ["rt-multi-thread", "macros", "sync"] }
sqlx = { version = "0.6", features = ["runtime-tokio-rustls", "sqlite"] }
```

### For auth-hub/Cargo.toml

```toml
[profile.release]
opt-level = "z"
lto = "thin"           # Faster than full LTO, still good
codegen-units = 1
panic = "abort"
strip = true

[dependencies]
tokio = { version = "1.0", features = ["rt-multi-thread", "macros", "fs"] }
# Minimal features only
```

## Expected Results

### Immediate Gains (Easy Optimizations)

```
Before (current):
  substrate: 35MB
  registry:  13MB
  auth-hub:  10MB
  Total:     58MB

After (Cargo profile + feature flags):
  substrate: 20MB  (43% reduction)
  registry:  7MB   (46% reduction)
  auth-hub:  6MB   (40% reduction)
  Total:     33MB  (43% reduction)
```

### Advanced Gains (Split Binaries)

```
substrate-minimal:  8MB   (only health, echo, substrate core)
substrate-storage: 12MB   (arbor, changelog, cone)
substrate-compute: 15MB   (jsexec, mustache, bash)
substrate-forge:   10MB   (hyperforge)

Total if running all: 45MB (vs 35MB single binary)
But typically run: ~20MB (minimal + 1-2 others)
```

### With UPX Compression

```
substrate: 20MB → 10MB  (50% compressed)
registry:  7MB  → 4MB   (43% compressed)
auth-hub:  6MB  → 3MB   (50% compressed)
Total:     33MB → 17MB
```

## Implementation Plan

### Phase 1: Low-Hanging Fruit (Immediate)

1. Add `[profile.release]` to all Cargo.toml files
2. Update Dockerfiles to use optimized builds
3. Test that everything still works

**Effort:** 30 minutes
**Reduction:** ~40%

### Phase 2: Feature Optimization (Medium)

1. Audit dependency features
2. Remove unused features
3. Update Cargo.toml with minimal features
4. Test thoroughly

**Effort:** 2-4 hours
**Reduction:** Additional 10-20%

### Phase 3: Modular Activations (Advanced)

1. Make activations optional features
2. Create minimal/full build variants
3. Update docker-compose with variants
4. Document which variant to use

**Effort:** 1-2 days
**Reduction:** Up to 70% for minimal builds

## Comparison with Other Projects

**Similar Rust projects:**

```
actix-web (simple server):   ~5MB   (single purpose)
tokio + axum hello-world:    ~3MB   (minimal features)
substrate (our hub):         35MB   (13 activations, full featured)

cargo-watch:                 ~8MB   (CLI tool)
ripgrep:                     ~4MB   (optimized, single purpose)
bat:                         ~3MB   (optimized, focused)
```

**Our binaries are large because:**
- Multiple subsystems (13 activations)
- Heavy dependencies (sqlx, V8, etc.)
- Full feature flags
- No optimization profile

**This is actually expected!** A 35MB binary with 13 different plugins, database, JavaScript engine, git operations, etc. is reasonable.

But we can still optimize it down to ~20MB with easy wins!

## Why Not Go Smaller?

We could make substrate <5MB, but tradeoffs:

- Split into many binaries → Deployment complexity
- Remove activations → Less functionality
- Aggressive compression → Slower startup
- Dynamic linking → Portability issues

**Sweet spot:** 15-25MB with all optimizations
- Still single binary
- Fast startup
- All features included
- 40-50% smaller than now

## Next Steps

1. Create optimized Cargo.toml configs
2. Update Dockerfiles to use them
3. Rebuild and measure
4. Document the results

Want me to implement Phase 1 (Cargo profile optimization)?
