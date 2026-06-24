# Security

- Token required for model gateway.
- Public bind disabled unless `ALLOW_PUBLIC_BIND=1`.
- Optional uncensored/NSFW-labeled model set is not pulled unless `ALLOW_UNSAFE_MODELS=1`.
- Firewall example:

```bash
sudo firewall-cmd --add-rich-rule='rule family=ipv4 source address=192.168.0.0/24 port port=7181 protocol=tcp accept' --permanent
sudo firewall-cmd --reload
```
