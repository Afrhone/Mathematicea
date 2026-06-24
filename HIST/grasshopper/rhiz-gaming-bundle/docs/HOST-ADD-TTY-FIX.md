# ceph-host-add TTY fix

If `ceph-host-add` fails with:

- `sudo: a terminal is required to read the password`
- `sudo: a password is required`

then the older bundle is using a plain `ssh` call for the remote `sudo` step.

This bundle fixes that by forcing a TTY with `ssh -tt` during the root key installation step and transferring the public key safely through `sudo -E`.

## Manual workaround on older bundles

Run this from the Ceph admin/bootstrap host:

```bash
pubkey_b64=$(sudo base64 -w0 /etc/ceph/ceph.pub)
ssh -tt -p 22 kobalt@192.168.0.2 "PUBKEY_B64='$pubkey_b64' sudo -E bash -s" <<'REMOTE'
install -d -m 700 /root/.ssh
touch /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys
key="$(printf '%s' "$PUBKEY_B64" | base64 -d)"
grep -qxF "$key" /root/.ssh/authorized_keys || printf '%s\n' "$key" >> /root/.ssh/authorized_keys
REMOTE
```

Then continue with:

```bash
sudo ceph orch host add rhiz-ueth 10.42.0.2
sudo ceph orch host label add rhiz-ueth _admin
```

Adjust the SSH user, port, and Ceph address as needed.
