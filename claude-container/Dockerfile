# Dockerfile for running Claude Code on Hypermemetic
# Extends the claude-container base with Haskell + extra tools
#
# Usage:
#   claude-container -s rebrand --config .claude-projects.yml --dockerfile Dockerfile.claude-container --build

FROM ghcr.io/hypermemetic/claude-container:latest

USER root
ENV DEBIAN_FRONTEND=noninteractive

# ===========================================
# System Dependencies (base already has Rust, Node, etc.)
# ===========================================
RUN apt-get update && apt-get install -y \
    # Build tools
    build-essential \
    pkg-config \
    libssl-dev \
    # Haskell dependencies
    libgmp-dev \
    libffi-dev \
    libncurses-dev \
    libtinfo-dev \
    zlib1g-dev \
    # SQLite (for substrate sqlx)
    libsqlite3-dev \
    sqlite3 \
    # Extra tools
    jq \
    htop \
    sudo \
    && rm -rf /var/lib/apt/lists/* \
    && YQ_ARCH=$(dpkg --print-architecture) \
    && curl -fsSL "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_${YQ_ARCH}" -o /usr/local/bin/yq \
    && chmod +x /usr/local/bin/yq

# ===========================================
# Add Rust components (Rust already installed in base)
# ===========================================
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH

RUN rustup component add rust-analyzer 2>/dev/null || true \
    && cargo binstall -y sqlx-cli 2>/dev/null || cargo install sqlx-cli

# ===========================================
# Haskell (GHCup)
# ===========================================
ENV GHCUP_INSTALL_BASE_PREFIX=/usr/local \
    PATH=/usr/local/.ghcup/bin:$PATH

RUN curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | \
    BOOTSTRAP_HASKELL_NONINTERACTIVE=1 \
    BOOTSTRAP_HASKELL_GHC_VERSION=9.4.8 \
    BOOTSTRAP_HASKELL_CABAL_VERSION=latest \
    BOOTSTRAP_HASKELL_INSTALL_NO_STACK=1 \
    sh \
    && ghcup install ghc 9.4.8 --set \
    && ghcup install cabal latest --set \
    && cabal update \
    && chmod -R a+rwX /usr/local/.ghcup /root/.cabal 2>/dev/null || true

# ===========================================
# Environment
# ===========================================
ENV RUST_LOG=info \
    RUST_BACKTRACE=1 \
    SQLX_OFFLINE=true

WORKDIR /workspace
