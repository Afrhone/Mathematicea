# Security gates

- Do not expose Open Terminal, Docker socket, LXD socket, or Ceph keyrings publicly.
- Keep gateway auth enabled.
- Use SSO or VPN in front of `outpost.aheap.afrho.net`.
- Treat external model responses as untrusted text. Never pipe them directly into shell.
- Collector is read-only by default, but Docker/LXD sockets can still leak sensitive inventory; run the profile only on trusted hosts.
- Separate cloud burst credentials from local operator SSH credentials.
