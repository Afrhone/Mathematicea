# Rollback

1. Keep GitLab canonical branch untouched until review.
2. Import Jules PR branch as `jules/pr-N` and review through GitLab MR.
3. Keep source services running until target validation and operator gate.
4. Gateway bootstrap tokens are revocable by node id.
5. LXD dev environments are disposable; delete them instead of mutating production.

```bash
git switch main
git branch -D jules/pr-N || true
lxc stop rhiz-dev --force
lxc delete rhiz-dev
```
