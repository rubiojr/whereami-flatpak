# Building whereami as a Flatpak

This directory contains the Flatpak manifest and related files for building [whereami](https://github.com/rubiojr/whereami) as a Flatpak application.

## Quick Start

The easiest way to build and install the Flatpak is using the Makefile targets:

```bash
# Build and install the Flatpak (user installation)
make flatpak-install

# Run the installed Flatpak
make flatpak-run

# Clean build artifacts
make flatpak-clean

# Rebuild from scratch
make flatpak-rebuild
```

## Releasing a Tagged Version

After pushing a `whereami` tag, update this repository with that exact tag:

```bash
./scripts/release update v0.1.11
```

The update command:

1. Checks out the tag from `rubiojr/whereami` and resolves its commit.
2. Regenerates `go.mod.json` and `modules.txt` from the tagged source.
3. Updates the tag and commit in the Flatpak manifest.
4. Stops so that you can review the generated changes.

Review and test the update, then commit and push it normally:

```bash
git diff
make flatpak-rebuild
git add io.github.rubiojr.whereami.yml go.mod.json modules.txt
git commit -m "Update whereami to v0.1.11"
git push
```

Publish after the packaging commit has been pushed:

```bash
./scripts/release publish
```

The publish command verifies that the worktree is clean and the current commit is on the remote branch. It then performs a fresh Flatpak build, creates or reuses the matching `rubiojr/whereami` GitHub release, uploads the bundle, and publishes the release. Pass the tag explicitly with `./scripts/release publish v0.1.11` if desired; it must match the manifest.

The command refuses to overwrite an asset on an already published release. If replacement is intentional, use `./scripts/release publish --force v0.1.11`.

The equivalent Make targets are `make release-update TAG=v0.1.11` and `make release-publish`.

The release script requires `git` and `go` for updates. Publishing additionally requires `make`, `flatpak`, `flatpak-builder`, and an authenticated `gh` CLI.

## Prerequisites

Install `flatpak` and `flatpak-builder` using your system package manager. The Makefile adds a user-scoped Flathub remote and lets `flatpak-builder` install the exact runtime, SDK, and Go extension required by the manifest automatically.

To configure the remote manually:

```bash
flatpak remote-add --user --if-not-exists flathub \
  https://flathub.org/repo/flathub.flatpakrepo
```

### Local Development Builds

The manifest uses a `git` source which fetches from GitHub. For local development with uncommitted changes, you can temporarily change the source to use a local directory:

```yaml
# In io.github.rubiojr.whereami.yml, replace the git source with:
sources:
  - type: dir
    path: ..
  - type: file
    path: modules.txt
  - go.mod.json
```

**Important**: Don't commit this change! The `type: git` source is required for distribution (e.g., Flathub).

## Files in this Directory

- **`io.github.rubiojr.whereami.yml`** - The Flatpak manifest that defines how to build the application
- **`go.mod.json`** - Pre-generated Go module sources for offline building (no network access needed during build)
- **`README.md`** - This file

## How It Works

The Flatpak build process:

1. **Downloads Go modules offline** - The `go.mod.json` file contains pre-downloaded URLs for all Go dependencies, so the build doesn't require network access during compilation
2. **Builds `miqt-rcc`** - First builds the Qt resource compiler tool needed for QML resources
3. **Generates resources** - Runs `go generate` to compile QML files into the binary
4. **Builds the application** - Compiles the Go application with vendored dependencies
5. **Installs desktop integration** - Installs the `.desktop` file and application icon

## Updating Go Dependencies

The release script regenerates `go.mod.json` and `modules.txt` automatically. To regenerate them manually from a local `whereami` checkout:

```bash
# Run from the whereami source checkout and point -out at this repository.
go run github.com/dennwc/flatpak-go-mod@v0.1.0 \
  -json -out ../whereami-flatpak .
```

**Note**: The `flatpak-go-mod` tool generates two files:
- `go.mod.json` - Archive sources for all Go dependencies
- `modules.txt` - The Go vendor modules list

Both files must be regenerated together whenever dependencies change.

## Permissions

The Flatpak has the following permissions:

- **Graphics**: Wayland and X11 (fallback) support
- **Network**: Required for downloading map tiles
- **Location services**: Access to GeoClue2 for device location
- **Filesystem**: Can create/write to `~/Documents/whereami/` for bookmarks

These are defined in the `finish-args` section of the manifest.

## Troubleshooting

**"Can't find ref..." error**
- Ensure you have installed the correct KDE Platform/SDK version (6.9)
- Run: `flatpak list | grep org.kde`

**Build failures with "rcc not found"**
- This should be handled automatically by the manifest
- The Qt `rcc` tool is in `/usr/libexec/rcc` within the KDE SDK

**Permission denied on rofiles-fuse**
- Clean up stale mount points: `flatpak-builder --force-clean build-dir io.github.rubiojr.whereami.yml`
- Or use the make target: `make flatpak-clean && make flatpak-install`

**Go module download errors**
- The build should work offline using `go.mod.json`
- If you see download errors, the `go.mod.json` may be outdated - regenerate it

## Development Workflow

When developing and testing Flatpak changes:

```bash
# 1. Make changes to source code or manifest
# 2. Rebuild and install
make flatpak-rebuild

# 3. Test the application
make flatpak-run

# 4. Check logs if needed
flatpak run --command=sh io.github.rubiojr.whereami
```

## Uninstalling

To remove the installed Flatpak:

```bash
flatpak uninstall --user io.github.rubiojr.whereami
```

To also remove build artifacts:

```bash
make flatpak-clean
```
