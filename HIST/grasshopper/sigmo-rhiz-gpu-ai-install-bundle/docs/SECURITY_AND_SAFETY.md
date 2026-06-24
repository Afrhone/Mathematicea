# Security and safety controls

This bundle is for legitimate local AI infrastructure. It does not include exploit, stealth, malware, credential theft, or destructive automation.

Risky model profiles are disabled by default:

```bash
ENABLE_RISKY_MODEL_PROFILES=false
ALLOW_HF_GIT_LFS_PULLS=false
```

Admin control endpoints require:

```text
X-RHIZ-Admin-Token: $RHIZ_ADMIN_TOKEN
```

Recommended production hardening:

1. Replace placeholder tokens.
2. Put gateway/UI behind Caddy/Nginx with TLS.
3. Keep firewalld allowlists restricted to RHIZ client IPs.
4. Use separate lab network for untrusted model experiments.
5. Log all provider calls in Mongo and review traces.
