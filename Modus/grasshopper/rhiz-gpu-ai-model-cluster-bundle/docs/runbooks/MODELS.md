# Models

Safe/default:

```bash
./scripts/models/pull_safe_models.sh
```

Optional unsafe/uncensored/NSFW-labeled list:

```bash
ALLOW_UNSAFE_MODELS=1 ./scripts/models/pull_optional_models.sh
```

Large 40B/128B model downloads can require hundreds of GB. Use `plan_models.sh` first.
