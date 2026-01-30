# Clawdbot for Umbrel

Personal AI assistant for Umbrel. Connects to WhatsApp, Telegram, Discord, Slack, and more.

## Included Tools

| Tool | Purpose |
|------|---------|
| **Chromium + Playwright** | Browser automation and web scraping |
| **FFmpeg** | Audio/video processing |
| **ImageMagick** | Image manipulation |
| **sox** | Audio processing |
| **sag** | ElevenLabs TTS CLI |
| **whisper** | OpenAI speech-to-text |
| **mcporter** | MCP server management |
| **uv/uvx** | Python tool runner |
| **gh** | GitHub CLI |
| **wacli** | WhatsApp CLI for syncing, searching, and sending messages |
| **Tailscale** | Remote access and Tailscale Serve |
| **ripgrep** | Fast search |
| **xvfb** | Virtual framebuffer for headless browsers |
| **bun** | Fast JavaScript runtime and package manager |
| **codex** | OpenAI Codex CLI for AI-powered coding assistance |

## Building the Docker Image

Build and push the image to your own registry:

```bash
# Build for multiple architectures
docker buildx create --use
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t ghcr.io/YOUR_USERNAME/clawdbot-umbrel:latest \
  --push \
  .
```

Or build locally for testing:

```bash
docker build -t clawdbot-umbrel:local .
```

## Installing on Umbrel

### Option 1: Community App Store

1. Fork this repo to your GitHub
2. Update `docker-compose.yml` with your image name
3. Add your repo as a community app store in Umbrel settings
4. Install Clawdbot from the store

### Option 2: Manual Installation

1. SSH into your Umbrel
2. Copy files to `/home/umbrel/umbrel/app-data/clawdbot/`
3. Run: `~/umbrel/scripts/app install clawdbot`

## Environment Variables

### LLM Providers (set at least one)

| Variable | Description |
|----------|-------------|
| `ANTHROPIC_API_KEY` | Anthropic API key (recommended) |
| `OPENAI_API_KEY` | OpenAI API key |
| `OPENROUTER_API_KEY` | OpenRouter API key |
| `OPENCODE_BASE_URL` | Local model endpoint (e.g., `http://ollama:11434/v1`) |
| `OPENCODE_MODEL` | Model name for local provider |
| `CLAWDBOT_MODEL` | Override auto-selected model |

### Channels

| Variable | Description |
|----------|-------------|
| `TELEGRAM_BOT_TOKEN` | Telegram bot token from @BotFather |
| `TELEGRAM_ALLOWED_USERS` | Comma-separated user IDs |
| `WHATSAPP_ENABLED` | Set to `true` to enable WhatsApp |
| `DISCORD_BOT_TOKEN` | Discord bot token |
| `SLACK_APP_TOKEN` | Slack app token (`xapp-...`) |
| `SLACK_BOT_TOKEN` | Slack bot token (`xoxb-...`) |

### Tools & Features

| Variable | Default | Description |
|----------|---------|-------------|
| `ENABLE_BROWSER` | `true` | Enable browser automation |
| `ENABLE_EXEC` | `true` | Enable shell execution |
| `BRAVE_API_KEY` | - | Brave Search API for web search |
| `ELEVENLABS_API_KEY` | - | ElevenLabs API for TTS |
| `AGENT_TIMEZONE` | `UTC` | Timezone for the agent |

## First-Time Setup

After installation:

1. Open Clawdbot from your Umbrel dashboard
2. Go to Settings and enter your API key (Anthropic, OpenAI, etc.)
3. Configure channels (WhatsApp, Telegram, etc.)

### CLI Access

Run CLI commands via docker exec:

```bash
# Check status
docker exec -it gw-clawdbot_gateway_1 clawdbot status

# Run onboarding wizard
docker exec -it gw-clawdbot_gateway_1 clawdbot onboard

# Login to WhatsApp (scan QR)
docker exec -it gw-clawdbot_gateway_1 clawdbot channels login

# Add Telegram bot
docker exec -it gw-clawdbot_gateway_1 clawdbot channels add --channel telegram --token "YOUR_TOKEN"

# Check health
docker exec -it gw-clawdbot_gateway_1 clawdbot health

# Run doctor
docker exec -it gw-clawdbot_gateway_1 clawdbot doctor
```

### Using wacli (WhatsApp CLI)

wacli is included for advanced WhatsApp management from the command line:

```bash
# Authenticate with WhatsApp (shows QR code)
docker exec -it gw-clawdbot_gateway_1 wacli auth

# Start sync mode to continuously sync messages
docker exec -it gw-clawdbot_gateway_1 wacli sync --follow

# Search messages
docker exec -it gw-clawdbot_gateway_1 wacli messages search "meeting"

# Send a text message
docker exec -it gw-clawdbot_gateway_1 wacli send text --to 1234567890 --message "hello"

# Send a file
docker exec -it gw-clawdbot_gateway_1 wacli send file --to 1234567890 --file /path/to/file.jpg --caption "photo"

# List groups
docker exec -it gw-clawdbot_gateway_1 wacli groups list

# Run diagnostics
docker exec -it gw-clawdbot_gateway_1 wacli doctor
```

**Note:** wacli data (authentication, message history, contacts) is persisted in `${APP_DATA_DIR}/data/wacli` and mapped to `/root/.wacli` in the container.

## Using with Local Models (Ollama)

If you have Ollama running on your Umbrel:

```yaml
environment:
  OPENCODE_BASE_URL: http://ollama:11434/v1
  OPENCODE_MODEL: llama3.1
```

Or if Ollama is on the host:

```yaml
environment:
  OPENCODE_BASE_URL: http://host.docker.internal:11434/v1
  OPENCODE_MODEL: llama3.1
```

## Tailscale Integration

The image includes Tailscale. To enable Tailscale Serve:

1. SSH into Umbrel and exec into the container:
   ```bash
   docker exec -it gw-clawdbot_gateway_1 bash
   ```

2. Authenticate with Tailscale:
   ```bash
   tailscale up
   ```

3. Edit config at `/root/.clawdbot/clawdbot.json`:
   ```json
   {
     "gateway": {
       "bind": "loopback",
       "tailscale": {
         "mode": "serve"
       }
     }
   }
   ```

4. Restart the container

**Note:** Tailscale device identity and state are already persisted in `${APP_DATA_DIR}/data/config` (as `/root/.clawdbot/tailscale.state`), so you won't need to re-authenticate after container restarts.

## Data Directories

| Path | Purpose |
|------|---------|
| `${APP_DATA_DIR}/data/config` | Configuration, credentials, sessions, Tailscale state |
| `${APP_DATA_DIR}/data/workspace` | Workspace, memory, skills, projects |
| `${APP_DATA_DIR}/data/claude` | Claude Code configuration |
| `${APP_DATA_DIR}/data/codex` | Codex CLI configuration, auth, history, sessions |
| `${APP_DATA_DIR}/data/wacli` | wacli WhatsApp data (auth, message history, contacts) |
| `${APP_DATA_DIR}/data/gh` | GitHub CLI authentication and settings |

## Troubleshooting

**Gateway won't start:**
```bash
docker logs gw-clawdbot_gateway_1
```

**Reset configuration:**
```bash
docker exec -it gw-clawdbot_gateway_1 clawdbot reset --config
```

**WhatsApp not connecting:**
```bash
# Re-scan QR code
docker exec -it gw-clawdbot_gateway_1 clawdbot channels login
```

**Browser tool not working:**
```bash
# Check if xvfb is running
docker exec -it gw-clawdbot_gateway_1 ps aux | grep Xvfb
```

## Image Size

The full-featured image is approximately 2-3GB due to:
- Node.js + Clawdbot
- Chromium browser
- Go runtime (sag)
- Python + Whisper
- FFmpeg, ImageMagick
- Tailscale

## Links

- [Clawdbot Documentation](https://docs.clawd.bot)
- [Clawdbot GitHub](https://github.com/clawdbot/clawdbot)
- [Clawdbot Discord](https://discord.gg/clawdbot)
