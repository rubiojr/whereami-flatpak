# WhereAmI Flatpak

This repository has one entry point. Both modes create:

```text
io.github.rubiojr.whereami.flatpak
```

## Development

Build the local WhereAmI checkout, including uncommitted changes:

```bash
./build dev ../whereami
```

The source directory defaults to `..`, so this is equivalent when the Flatpak
repository is nested inside the WhereAmI checkout:

```bash
./build dev
```

Test the bundle:

```bash
flatpak install --user --reinstall io.github.rubiojr.whereami.flatpak
flatpak run --user io.github.rubiojr.whereami
```

## Release

After tagging WhereAmI, build that exact tag from a clean checkout:

```bash
./build release v0.1.12 ../whereami
```

Release mode refuses to build when:

- the WhereAmI checkout is dirty;
- the tag does not exist; or
- the tag is not checked out at `HEAD`.

Test the resulting bundle with the same `flatpak install --reinstall` command.
Uploading it to GitHub Releases is a separate manual step after validation.

## Build Behavior

`./build` regenerates Flatpak Go dependency sources from the selected checkout
before invoking flatpak-builder. Development mode uses the dirty local source;
release mode uses the exact tagged Git source. Generated dependency metadata is
temporary and never modifies either checkout.

MapLibre Native Qt is built inside the Flatpak against the pinned KDE/Qt
runtime. Its commit is pinned in `maplibre-native-qt.yml` because its QtLocation
plugin links Qt private APIs.

Requirements: `flatpak`, `flatpak-builder`, `git`, Go, `jq`, and `tar`.

## Licensing

The packaging files are MIT licensed; see `LICENSE`. The bundle also includes:

| Component | License |
| --- | --- |
| WhereAmI | MIT |
| MapLibre Native Qt core | BSD-2-Clause |
| MapLibre Native Qt Location | LGPL-3.0-only OR GPL-2.0-only OR GPL-3.0-only |
| Vendored MapLibre dependencies | See bundled upstream notices |

WhereAmI distributes the MapLibre Location component under LGPL-3.0-only. The
exact MapLibre source commit and build configuration are recorded in
`maplibre-native-qt.yml`, and the libraries are dynamically linked. Upstream
license texts and notices are installed under
`/app/share/licenses/io.github.rubiojr.whereami/`.
