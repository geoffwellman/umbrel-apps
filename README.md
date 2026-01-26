# Umbrel Community Apps

Personal Umbrel app store with custom apps.

## Installation

Add this repo as a community app store in Umbrel:

**Settings → App Stores → Add** → `https://github.com/geoffwellman/umbrel-apps`

## Available Apps

| App | Description |
|-----|-------------|
| [Clawdbot](./clawdbot) | Personal AI assistant with WhatsApp, Telegram, Discord support |

## Adding a New App

1. Create a folder with your app name (e.g., `my-app/`)
2. Add required files:
   - `umbrel-app.yml` - App manifest
   - `docker-compose.yml` - Docker Compose configuration
   - `Dockerfile` (optional) - If building a custom image
3. Add a build job to `.github/workflows/build.yml` if needed
4. Push to main branch

## Structure

```
umbrel-apps/
├── clawdbot/
│   ├── Dockerfile
│   ├── docker-compose.yml
│   ├── umbrel-app.yml
│   ├── entrypoint.sh
│   └── exports.sh
├── another-app/
│   ├── docker-compose.yml
│   └── umbrel-app.yml
├── .github/workflows/
│   └── build.yml
└── README.md
```

## Links

- [Umbrel App Development Guide](https://github.com/getumbrel/umbrel-apps)
- [Umbrel Community](https://community.umbrel.com)
