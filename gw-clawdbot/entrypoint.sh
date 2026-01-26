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

# Create/update both YAML and JSON configs to ensure clawdbot finds the setting
CONFIG_YML="$HOME/.clawdbot/config.yml"
CONFIG_JSON="$HOME/.clawdbot/config.json"

echo "Setting up config with HTTP access enabled..."

# Always write config to ensure allowInsecureAuth is set
cat > "$CONFIG_YML" << 'EOF'
# Clawdbot Configuration (auto-generated for Umbrel)
gateway:
  mode: local
  controlUi:
    allowInsecureAuth: true
EOF

cat > "$CONFIG_JSON" << 'EOF'
{
  "gateway": {
    "mode": "local",
    "controlUi": {
      "allowInsecureAuth": true
    }
  }
}
EOF

echo "Config files created at $CONFIG_YML and $CONFIG_JSON"

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

# Run the main command
exec "$@"
