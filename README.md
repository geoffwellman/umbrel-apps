# Umbrel Community Apps

Personal Umbrel app store with custom apps.

## Installation

Add this repo as a community app store in Umbrel:

**Settings → App Stores → Add** → `https://github.com/geoffwellman/umbrel-apps`

## Available Apps

| App | Description |
|-----|-------------|
| [Clawdbot](./geoffwellman-geoffwellman-clawdbot) | Personal AI assistant with WhatsApp, Telegram, Discord support |

## Updating Apps

### Automatic Updates

Docker images rebuild automatically:
- **On push** to `main` branch (when app files change)
- **Weekly** on Sundays at midnight UTC

### Manual Update on Your Umbrel

After a new image is built:

```bash
# SSH into your Umbrel, then:
~/umbrel/scripts/app update geoffwellman-clawdbot
```

Or via the Umbrel web UI: Open the app → Settings → Check for Updates

### Triggering a Rebuild

To force a rebuild without code changes:
1. Go to GitHub → Actions → "Build Docker Images"
2. Click "Run workflow" → "Run workflow"

### Version Bumps

When releasing a new version with release notes:
1. Edit `geoffwellman-clawdbot/umbrel-app.yml`
2. Update `version` field
3. Update `releaseNotes` field
4. Commit and push

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
├── geoffwellman-clawdbot/
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
