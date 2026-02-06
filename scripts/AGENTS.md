# scripts/

Automation for validation and releases.

## Commands

```bash
# Compile + lint + tests
./scripts/validate.sh

# Export + package (runs bootstrap + validate internally)
./scripts/release.sh

# Install export templates + optional gdtoolkit
./scripts/bootstrap_build.sh
```

## Notes

- Uses `GODOT_BIN` env var (defaults to `godot`).
- `scripts/release.sh` writes to `build/` and packages archives into `dist/`.
