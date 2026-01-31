#!/bin/bash
set -e

# =============================================================================
# OpenClaw Entrypoint Script
# Handles xvfb for headless browser and optional services
# =============================================================================

echo "=== OpenClaw Starting ==="
echo "============================================"

# Ensure config directory exists and set insecure auth for HTTP access
mkdir -p "$HOME/.openclaw"

# The config file is openclaw.json (not config.yml or config.json)
CONFIG_FILE="$HOME/.openclaw/openclaw.json"

# Only create if it doesn't exist (preserve user settings)
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Creating default config with HTTP access enabled..."
    cat > "$CONFIG_FILE" << 'EOF'
{
  "gateway": {
    "controlUi": {
      "allowInsecureAuth": true
    }
  }
}
EOF
    echo "Config created at $CONFIG_FILE"
else
    echo "Config exists at $CONFIG_FILE"
fi

# Start Xvfb for headless browser support
if [ "${ENABLE_BROWSER:-true}" = "true" ]; then
    echo "Starting Xvfb virtual display..."
    # Clean up any existing Xvfb processes and lock files from previous runs
    pkill -9 Xvfb 2>/dev/null || true
    rm -f /tmp/.X99-lock 2>/dev/null || true
    rm -rf /tmp/.X11-unix/X99 2>/dev/null || true
    sleep 1
    Xvfb :99 -screen 0 1920x1080x24 -ac &
    export DISPLAY=:99
fi

# Print configuration summary (redact secrets)
echo "Gateway Port: ${CLAWDBOT_GATEWAY_PORT:-18789}"
echo "Gateway Bind: ${GATEWAY_BIND:-lan}"
echo "Browser: ${ENABLE_BROWSER:-true}"
echo "Exec: ${ENABLE_EXEC:-true}"

# Check for API keys (don't print them)
if [ -n "$ANTHROPIC_API_KEY" ]; then
    echo "Provider: Anthropic [configured]"
fi
if [ -n "$OPENAI_API_KEY" ]; then
    echo "Provider: OpenAI [configured]"
fi
if [ -n "$OPENROUTER_API_KEY" ]; then
    echo "Provider: OpenRouter [configured]"
fi
if [ -n "$OPENCODE_BASE_URL" ]; then
    echo "Provider: OpenCode/Local [configured] -> $OPENCODE_BASE_URL"
fi

# Check for channels
if [ -n "$TELEGRAM_BOT_TOKEN" ]; then
    echo "Channel: Telegram [configured]"
fi
if [ "$WHATSAPP_ENABLED" = "true" ]; then
    echo "Channel: WhatsApp [enabled]"
fi
if [ -n "$DISCORD_BOT_TOKEN" ]; then
    echo "Channel: Discord [configured]"
fi
if [ -n "$SLACK_BOT_TOKEN" ]; then
    echo "Channel: Slack [configured]"
fi

echo "============================================"

# Read Tailscale auth key from env var OR from persistent config file
# Config file survives updates: ~/umbrel/app-data/gw-clawdbot/data/config/tailscale.env
TS_ENV_FILE="$HOME/.openclaw/tailscale.env"
if [ -z "${TAILSCALE_AUTHKEY:-}" ] && [ -f "$TS_ENV_FILE" ]; then
    echo "Loading Tailscale config from $TS_ENV_FILE"
    . "$TS_ENV_FILE"
fi

# Start Tailscale if auth key is available (from env or config file)
if [ -n "${TAILSCALE_AUTHKEY:-}" ]; then
    echo "Starting Tailscale (userspace mode)..."
    mkdir -p /var/run/tailscale
    # Clean up if previous run created state as a directory
    if [ -d "/root/.openclaw/tailscale.state" ]; then
        rm -rf /root/.openclaw/tailscale.state
    fi
    # Also clean up old directory-style state
    if [ -d "/root/.openclaw/tailscale" ]; then
        rm -rf /root/.openclaw/tailscale
    fi
    tailscaled --state=/root/.openclaw/tailscale.state --socket=/var/run/tailscale/tailscaled.sock --tun=userspace-networking &
    sleep 3
    if tailscale up --authkey="$TAILSCALE_AUTHKEY" --hostname="${TAILSCALE_HOSTNAME:-clawdbot}" 2>&1; then
        echo "Tailscale: $(tailscale ip -4 2>/dev/null || echo 'connecting...')"
        # Set up Tailscale Serve for HTTPS if requested
        if [ "${TAILSCALE_SERVE:-true}" = "true" ]; then
            tailscale serve --bg https / http://localhost:18789 2>/dev/null || true
            echo "Tailscale Serve: HTTPS enabled"
        fi
    else
        echo "Tailscale: failed to start (clawdbot will continue without it)"
    fi
else
    echo "Tailscale: not configured"
    echo "  To enable, create: ~/umbrel/app-data/gw-clawdbot/data/config/tailscale.env"
    echo "  With: TAILSCALE_AUTHKEY=tskey-auth-YOUR_KEY_HERE"
fi

echo "============================================"

# Run the main command
exec "$@"
