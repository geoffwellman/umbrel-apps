#!/bin/bash
set -e

# =============================================================================
# Clawdbot Entrypoint Script
# Handles xvfb for headless browser and optional services
# =============================================================================

echo "=== Clawdbot Starting ==="
echo "============================================"

# Ensure config directory exists and set insecure auth for HTTP access
mkdir -p "$HOME/.clawdbot"

# The config file is clawdbot.json (not config.yml or config.json)
CONFIG_FILE="$HOME/.clawdbot/clawdbot.json"

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

# Start Tailscale if auth key is provided
if [ -n "${TAILSCALE_AUTHKEY:-}" ]; then
    echo "Starting Tailscale..."
    tailscaled --state=/root/.clawdbot/tailscale/ --socket=/var/run/tailscale/tailscaled.sock &
    sleep 2
    tailscale up --authkey="$TAILSCALE_AUTHKEY" --hostname="${TAILSCALE_HOSTNAME:-clawdbot}"
    echo "Tailscale: $(tailscale ip -4 2>/dev/null || echo 'connecting...')"

    # Set up Tailscale Serve for HTTPS if requested
    if [ "${TAILSCALE_SERVE:-true}" = "true" ]; then
        tailscale serve --bg https / http://localhost:18789 2>/dev/null || true
        echo "Tailscale Serve: HTTPS enabled"
    fi
else
    echo "Tailscale: not configured (set TAILSCALE_AUTHKEY to enable)"
fi

echo "============================================"

# Run the main command
exec "$@"
