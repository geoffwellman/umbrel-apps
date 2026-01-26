# Clawdbot Umbrel Image
# Full-featured build with all tools for browser, voice, media, and MCP support
#
# Included tools:
# - Chromium + Playwright (browser automation)
# - FFmpeg (audio/video processing)
# - ImageMagick (image manipulation)
# - sag (ElevenLabs TTS)
# - whisper (OpenAI speech-to-text)
# - mcporter (MCP server management)
# - uv/uvx (Python tool runner)
# - gh (GitHub CLI)
# - Tailscale (remote access)
# - ripgrep (fast search)
# - sox (audio processing)

# =============================================================================
# Stage 1: Dependencies - System packages, Go, Python tools
# =============================================================================
FROM node:22-bookworm AS deps

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Core utilities
    curl \
    wget \
    ca-certificates \
    gnupg \
    git \
    jq \
    ripgrep \
    unzip \
    # Media processing
    ffmpeg \
    imagemagick \
    sox \
    libsox-fmt-all \
    # Browser automation (Chromium + dependencies)
    chromium \
    fonts-liberation \
    fonts-noto-color-emoji \
    fonts-noto-cjk \
    xvfb \
    # Tailscale dependencies
    iptables \
    iproute2 \
    # Build tools
    build-essential \
    pkg-config \
    # Audio dev libraries (for sag TTS)
    libasound2-dev \
    # Python for whisper/uv
    python3 \
    python3-pip \
    python3-venv \
    # Cleanup
    && rm -rf /var/lib/apt/lists/*

# Install Tailscale
RUN curl -fsSL https://pkgs.tailscale.com/stable/debian/bookworm.noarmor.gpg | tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null \
    && curl -fsSL https://pkgs.tailscale.com/stable/debian/bookworm.tailscale-keyring.list | tee /etc/apt/sources.list.d/tailscale.list \
    && apt-get update \
    && apt-get install -y tailscale \
    && rm -rf /var/lib/apt/lists/*

# Install GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list \
    && apt-get update \
    && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

# Install Go (for sag TTS)
ENV GOLANG_VERSION=1.24.0
RUN curl -fsSL "https://go.dev/dl/go${GOLANG_VERSION}.linux-$(dpkg --print-architecture).tar.gz" | tar -C /usr/local -xz
ENV PATH="/usr/local/go/bin:/root/go/bin:${PATH}"

# Install sag (ElevenLabs TTS CLI)
RUN go install github.com/steipete/sag/cmd/sag@latest

# Install uv (fast Python package manager for MCP tools)
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:${PATH}"

# Install OpenAI Whisper (speech-to-text)
RUN uv pip install --system --break-system-packages openai-whisper

# Install mcporter (MCP server management)
RUN npm install -g mcporter

# Install Bun (used by some build scripts and skills)
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:${PATH}"

# Enable corepack for pnpm
RUN corepack enable

# =============================================================================
# Stage 2: Builder - Clone and build Clawdbot
# =============================================================================
FROM deps AS builder

WORKDIR /app

# Clone and build Clawdbot
ARG CLAWDBOT_VERSION=main
RUN git clone --depth 1 --branch ${CLAWDBOT_VERSION} https://github.com/clawdbot/clawdbot.git . \
    && pnpm install --frozen-lockfile \
    && pnpm build \
    && pnpm ui:install \
    && pnpm ui:build \
    # Clean up dev dependencies and cache
    && pnpm prune --prod \
    && rm -rf /root/.npm /root/.cache /tmp/*

# =============================================================================
# Stage 3: Runtime - Final image
# =============================================================================
FROM deps AS runtime

WORKDIR /app

# Copy built Clawdbot from builder
COPY --from=builder /app /app

# Environment configuration
ENV NODE_ENV=production
ENV HOME=/root

# Chromium configuration for browser tools
ENV CHROME_PATH=/usr/bin/chromium
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium
ENV PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH=/usr/bin/chromium

# Display for headless browser (xvfb)
ENV DISPLAY=:99

# Create data directories
RUN mkdir -p /root/.clawdbot /root/clawd

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose ports
# 18789: Gateway (HTTP + WebSocket + WebChat)
# 18790: Bridge (TCP for mobile nodes)
EXPOSE 18789 18790

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:18789/health || exit 1

ENTRYPOINT ["/entrypoint.sh"]
CMD ["node", "dist/index.js", "gateway", "--bind", "lan", "--port", "18789"]
