# iPod nano Compatibility

Old iPod nano models do not run arbitrary Xcode apps. Depending on generation, they may support:

- synced music/audio,
- photos,
- videos in compatible formats,
- notes/contacts/calendars on some models,
- Nike/clock/radio firmware features on later models.

Recommended nano path:

```bash
./scripts/export-nano-media.sh
```

Then sync files in `exports/nano-media` through Finder/Music/iTunes depending on macOS version and device generation.
