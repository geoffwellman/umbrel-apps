# Clawdbot Umbrel Image - Minimal build for faster deployment
FROM node:22-bookworm-slim

# Install essential dependencies only
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    gnupg \
    git \
    ffmpeg \
    chromium \
    fonts-liberation \
    xvfb \
    iptables \
    iproute2 \
    ripgrep \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Install Tailscale
RUN curl -fsSL https://pkgs.tailscale.com/stable/debian/bookworm.noarmor.gpg | tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null \
    && curl -fsSL https://pkgs.tailscale.com/stable/debian/bookworm.tailscale-keyring.list | tee /etc/apt/sources.list.d/tailscale.list \
    && apt-get update \
    && apt-get install -y tailscale \
    && rm -rf /var/lib/apt/lists/*

# Install GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | tee /usr/share/keyrings/githubcli-archive-keyring.gpg > /dev/null \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

# Install Go, build wacli, then remove Go to minimize image size
RUN ARCH="$(dpkg --print-architecture)" \
    && case "${ARCH}" in \
        amd64) GO_ARCH='amd64' ;; \
        arm64) GO_ARCH='arm64' ;; \
        *) echo "Unsupported architecture: ${ARCH}" && exit 1 ;; \
    esac \
    && curl -fsSL "https://go.dev/dl/go1.23.5.linux-${GO_ARCH}.tar.gz" | tar -C /usr/local -xz \
    && export PATH="/usr/local/go/bin:${PATH}" \
    && git clone https://github.com/moltbot/wacli.git /tmp/wacli \
    && cd /tmp/wacli \
    && git checkout cc6a7a3cd9dce3a723751564d4d6c73d825ddfde \
    && go build -tags sqlite_fts5 -o /usr/local/bin/wacli ./cmd/wacli \
    && cd / \
    && rm -rf /tmp/wacli /usr/local/go /root/.cache/go-build /root/go

# Enable corepack for pnpm
RUN corepack enable

# Install bun globally with checksum verification
# Using pinned version v1.3.8 for reproducibility and security
ARG BUN_VERSION=1.3.8
RUN ARCH="$(dpkg --print-architecture)" \
    && case "${ARCH}" in \
        amd64) BUN_ARCH='x64' ;; \
        arm64) BUN_ARCH='aarch64' ;; \
        *) echo "Unsupported architecture: ${ARCH}" && exit 1 ;; \
    esac \
    && cd /tmp \
    && BUN_FILE="bun-linux-${BUN_ARCH}.zip" \
    && curl -fsSL "https://github.com/oven-sh/bun/releases/download/bun-v${BUN_VERSION}/${BUN_FILE}" -o "${BUN_FILE}" \
    && curl -fsSL "https://github.com/oven-sh/bun/releases/download/bun-v${BUN_VERSION}/SHASUMS256.txt" | grep "${BUN_FILE}" > "${BUN_FILE}.sha256" \
    && sha256sum -c "${BUN_FILE}.sha256" \
    && unzip "${BUN_FILE}" \
    && mv "bun-linux-${BUN_ARCH}/bun" /usr/local/bin/bun \
    && chmod +x /usr/local/bin/bun \
    && bun --version \
    && cd / \
    && rm -rf /tmp/bun-linux-*

WORKDIR /app
ENV CI=true

# Clone and build Clawdbot
ARG CLAWDBOT_VERSION=main
RUN git clone --depth 1 --branch ${CLAWDBOT_VERSION} https://github.com/clawdbot/clawdbot.git . \
    && pnpm install --frozen-lockfile \
    && pnpm build \
    && pnpm ui:install \
    && pnpm ui:build \
    && pnpm prune --prod \
    && rm -rf /root/.npm /root/.cache /tmp/* .git

# Link clawdbot CLI so the agent can run 'clawdbot' as a command
RUN printf '#!/bin/sh\nexec node /app/dist/index.js "$@"\n' > /usr/local/bin/clawdbot \
    && chmod +x /usr/local/bin/clawdbot

# Install Claude Code
RUN npm install -g @anthropic-ai/claude-code

# Install Codex CLI
RUN npm install -g @openai/codex

# Install agent-browser
RUN npm install -g agent-browser \
    && agent-browser install

# Environment configuration
ENV NODE_ENV=production
ENV HOME=/root
ENV CHROME_PATH=/usr/bin/chromium
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium
ENV PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH=/usr/bin/chromium
ENV DISPLAY=:99

# Create data directories
RUN mkdir -p /root/.clawdbot /root/clawd

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 18789 18790

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:18789/health || exit 1

ENTRYPOINT ["/entrypoint.sh"]
CMD ["node", "dist/index.js", "gateway", "--bind", "lan", "--port", "18789"]
