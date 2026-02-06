# Updates (GitHub Only)

This project supports a minimal "GitHub-only" update flow:

- You publish versions as GitHub Releases (tagged, e.g. `v1.2.3`).
- The game checks GitHub for the latest release and shows an in-game banner when an update is available.
- Clicking "Download & Restart" downloads the correct asset for the current OS, verifies SHA256, applies the update, and relaunches.

## Requirements

### Release assets

The updater expects these assets to exist on the GitHub Release:

- `SHA256SUMS.txt`
- `*_windows_x86_64.zip` (Windows)
- `*_linux_x86_64.AppImage` (Linux preferred)
  - fallback: `*_linux_x86_64.zip`

Our `scripts/release.sh` already produces these names.

### Project settings

Set these keys in `project.godot` `[application]`:

- `config/update_owner` (GitHub org/user)
- `config/update_repo` (repo name)

Example:

```
config/update_owner="my-org"
config/update_repo="neon-survivor"
```

The current game version is read from `config/version`.

## Publishing flow

Recommended flow:

1. Create a tag `vX.Y.Z`.
2. CI builds artifacts with `./scripts/release.sh` and uploads them to the Release.

Note: `scripts/release.sh` temporarily sets `config/version` to the build id (tag/sha) for export, and restores `project.godot` afterwards.

## Runtime behavior

- On startup (main menu), the game checks `https://api.github.com/repos/<owner>/<repo>/releases/latest`.
- If `tag_name` is greater than the current `config/version`, it shows the update panel.
- On click, it downloads the asset + `SHA256SUMS.txt`, validates SHA256, then runs a small OS script to replace files and relaunch.

### Caveats

- The updater cannot replace binaries if the install directory is not writable.
- On Windows/Linux, file replacement happens after the game quits (the updater script waits for the process PID to exit).
- GitHub API has rate limits; we throttle checks to once per 5 minutes by default.
