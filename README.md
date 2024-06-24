# Junbi - Server Setup and Hardening Tool

<p align="center">
  <img src="/docs/logo.png" alt="Junbi Logo" width="200"/>
</p>

<p align="center">
  <strong>Prepare your server with confidence</strong>
</p>

Junbi (準備), meaning "preparation" or "readiness" in Japanese, is a powerful and modular server setup and hardening tool. It's designed to quickly configure a secure, production-ready Ubuntu server with just a few commands.

## 🚀 Quick Start

Get your server up and running securely in minutes:

```bash
curl -sSL https://raw.githubusercontent.com/mr-karan/junbi/main/setup.sh | bash
```

⚠️ Always review scripts before running them with elevated privileges.

## 🛠️ What Junbi Sets Up

- A new sudo user with SSH key authentication
- Hardened SSH configuration (no root login, no password authentication)
- Essential system packages (vim, curl, etc.)
- Docker and Docker Compose
- Optimized sysctl settings for better performance and security
- Unattended security updates

## 🔧 Requirements

- A fresh Ubuntu server (tested on 24.04 LTS and later)
- Root SSH access to the server

## 📚 Manual Setup

1. Clone the repository:
   ```
   git clone https://github.com/yourusername/junbi.git
   ```
2. Navigate to the Junbi directory:
   ```
   cd junbi
   ```
3. Run the setup script:
   ```
   ./setup.sh
   ```
4. Follow the interactive prompts to customize your setup.

## 🛡️ Security Note

Junbi significantly improves your server's security posture, but it's not a silver bullet. Always follow security best practices, keep your systems updated, and regularly audit your server's configuration.

## 🤝 Contributing

Contributions are welcome! Whether it's bug reports, feature requests, or code contributions, please feel free to reach out or submit a pull request.

## 📜 License

Junbi is open-source software licensed under the MIT license.

