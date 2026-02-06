# Changelog

All notable changes to this project will be documented in this file.

The format is based on "Keep a Changelog" and uses semantic versioning.

## Unreleased

## v0.1.5 - 2026-02-06

- Fix CI: prevent set -e from aborting on Godot cleanup crash

## v0.1.4 - 2026-02-06

- Fix CI: tolerate Godot exit crash when export output exists

## v0.1.3 - 2026-02-06

- Fix CI: use dummy renderer to avoid GLES3 segfault on exit

## v0.1.2 - 2026-02-06

- Fix CI export by forcing X11+opengl3

## v0.1.1 - 2026-02-06

- Fix CI export crash by running Godot under Xvfb

## v0.1.0 - 2026-02-06

- Document src module conventions
- Add automated tests
- Add UI and visual effects
- Add game entities
- Add core game systems
- Add global autoload singletons
- Add data assets and catalogs
- Vendor gdUnit4 addon
- Add Godot project config and main world scene
- Ignore dist artifacts except release notes
