#!/bin/bash
set -e

# =============================================================================
# Clawdbot Entrypoint Script
# Handles xvfb for headless browser and optional services
# =============================================================================

echo "=== Clawdbot Starting ==="
echo "============================================"

# Start Xvfb for headless browser support
if [ "${ENABLE_BROWSER:-true}" = "true" ]; then
    echo "Starting Xvfb virtual display..."
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
