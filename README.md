# Junbi

**Interactive server setup for Ubuntu with sensible security defaults.**

Junbi (準備 - "preparation" in Japanese) is a simple tool that configures a fresh Ubuntu server with proper security, Docker, and essential tools through an interactive wizard.

## Why Junbi?

Setting up a new server properly is tedious:
- Creating users, configuring SSH, setting up firewalls
- Installing Docker, configuring auto-updates, optimizing sysctls
- Doing it all securely without missing critical steps

Junbi handles all of this in one interactive session with sensible defaults.

## Quick Start

```bash
# Run on your local machine (not on the server)
curl -sSL https://raw.githubusercontent.com/mr-karan/junbi/main/junbi.sh | bash

# Or download and run manually
curl -O https://raw.githubusercontent.com/mr-karan/junbi/main/junbi.sh
chmod +x junbi.sh
./junbi.sh
```

## What Gets Configured

**Security essentials** (always applied):
- New sudo user with SSH key authentication
- SSH hardening (custom port, no root login, no passwords)
- Basic firewall rules

**Optional components** (you choose):
- Docker & Docker Compose
- UFW Firewall & Fail2ban
- Monitoring tools (htop, btop, ncdu, glances)
- Zsh + Oh My Zsh
- Development tools
- Auto-updates
- System optimization

## How It Works

1. **Run locally** - Execute junbi.sh on your machine
2. **Interactive wizard** - Answer a few questions (server IP, username, SSH keys)
3. **Choose components** - Select what to install (Docker, monitoring, etc.)
4. **Automatic setup** - Junbi connects to your server and configures everything
5. **Secure access** - Connect with `ssh -p 2222 username@server-ip`

## Requirements

- **Local**: Any system with curl and bash
- **Server**: Ubuntu 24.04+ with root SSH access
- **Network**: SSH connectivity to the server

## License

MIT - see [LICENSE](LICENSE)

