# Makefile for whereami
#
# Provides convenience targets for:
#  - Local Go build / run / lint
#  - Flatpak build, install, run, clean
#  - Local desktop install (binary + .desktop + icon)
#
# Requirements (host, outside Flatpak):
#  - Go toolchain (matching go.mod version)
#  - qmllint-qt6 (for QML lint target) optional
#  - flatpak + flatpak-builder for Flatpak targets
#
# Flatpak manifest: flatpak/io.github.rubiojr.whereami.yml
#
# Common usage:
#   make flatpak-build
#   make flatpak-install
#
# Override variables if needed:
#   make FLATPAK_BUILDDIR=out/flatpak flatpak-build
#   make INSTALL_PREFIX=/custom/path install
#

APP_NAME          := whereami
APP_ID            := io.github.rubiojr.whereami
FLATPAK_MANIFEST  := $(APP_ID).yml
FLATPAK_BUILDDIR  := build-dir
FLATPAK_EXPORTDIR := export-dir
BIN_DIR           := bin
GO                := go
QML_LINT          := qmllint-qt6

# Optional: pass ldflags to reduce binary size
LDFLAGS := -s -w

# Desktop integration install prefixes (override INSTALL_PREFIX to relocate)
INSTALL_PREFIX    ?= $(HOME)/.local
BIN_INSTALL_DIR   := $(INSTALL_PREFIX)/bin
DESKTOP_DIR       := $(INSTALL_PREFIX)/share/applications
ICON_DIR_SCALABLE := $(INSTALL_PREFIX)/share/icons/hicolor/scalable/apps
ICON_SIZES        := 16 24 32 48 64 128 256
DESKTOP_FILE_SRC  := desktop/$(APP_ID).desktop
ICON_FILE_SRC     := ui/icons/$(APP_ID).svg
DESKTOP_FILE_DEST := $(DESKTOP_DIR)/$(APP_ID).desktop
ICON_FILE_DEST    := $(ICON_DIR_SCALABLE)/$(APP_ID).svg

# Detect OS/Arch (optional for logging)
HOST_OS   := $(shell uname -s)
HOST_ARCH := $(shell uname -m)

.PHONY: all build run clean lint fmt vet tidy qml-test \
        flatpak-build flatpak-install flatpak-run flatpak-clean flatpak-rebuild \
        install uninstall print-vars help \
        release release-snapshot release-rpm release-rpm-fedora check-release-deps

all: flatpak-build flatpak-bundle

########################################
# Flatpak targets
########################################

# Build (no install) into $(FLATPAK_BUILDDIR)
flatpak-build:
	@echo "==> Flatpak build (no install)"
	flatpak-builder --ccache $(FLATPAK_BUILDDIR) $(FLATPAK_MANIFEST)

# Build + install into user repo
flatpak-install:
	@echo "==> Flatpak build + install (user)"
	flatpak-builder --user --install --ccache $(FLATPAK_BUILDDIR) $(FLATPAK_MANIFEST)

# Run installed Flatpak
flatpak-run:
	@echo "==> Running Flatpak $(APP_ID)"
	flatpak run $(APP_ID)

# Remove build artifacts (does not uninstall the app)
flatpak-clean:
	@echo "==> Cleaning Flatpak build dirs"
	rm -rf $(FLATPAK_BUILDDIR) $(FLATPAK_EXPORTDIR)

# Clean + build + install (forces fresh build)
flatpak-rebuild:
	@echo "==> Cleaning and rebuilding Flatpak"
	flatpak-builder --user --force-clean --ccache $(FLATPAK_BUILDDIR) $(FLATPAK_MANIFEST)
	flatpak build-bundle $(FLATPAK_EXPORTDIR) $(APP_ID).flatpak $(APP_ID)

# Export and create a distributable .flatpak bundle
flatpak-bundle:
	@echo "==> Creating Flatpak bundle"
	@if [ ! -d "$(FLATPAK_BUILDDIR)" ]; then \
		echo "Build directory not found. Run 'make flatpak-build' first."; \
		exit 1; \
	fi
	@mkdir -p $(FLATPAK_EXPORTDIR)
	flatpak-builder --repo=$(FLATPAK_EXPORTDIR) --force-clean $(FLATPAK_BUILDDIR) $(FLATPAK_MANIFEST)
	flatpak build-bundle $(FLATPAK_EXPORTDIR) $(APP_ID).flatpak $(APP_ID)
	@echo "==> Flatpak bundle created: $(APP_ID).flatpak"

# Upload flatpak bundle to latest GitHub release
flatpak-release:
	@echo "==> Uploading Flatpak bundle to latest GitHub release"
	@if [ ! -f "$(APP_ID).flatpak" ]; then \
		echo "Error: $(APP_ID).flatpak not found. Run 'make flatpak-bundle' first."; \
		exit 1; \
	fi
	@if ! command -v gh >/dev/null 2>&1; then \
		echo "Error: gh (GitHub CLI) not found!"; \
		echo "Install from: https://cli.github.com/"; \
		exit 1; \
	fi
	@echo "Finding latest release..."
	@LATEST_TAG=$$(gh release list --limit 1 --json tagName --jq '.[0].tagName'); \
	if [ -z "$$LATEST_TAG" ]; then \
		echo "Error: No releases found"; \
		exit 1; \
	fi; \
	echo ""; \
	echo "Release: $$LATEST_TAG"; \
	echo "File:    $(APP_ID).flatpak"; \
	echo ""; \
	read -p "Upload to this release? [y/N] " -n 1 -r; \
	echo; \
	if [[ ! $$REPLY =~ ^[Yy]$$ ]]; then \
		echo "Upload cancelled."; \
		exit 1; \
	fi; \
	echo "Uploading to release $$LATEST_TAG..."; \
	gh release upload "$$LATEST_TAG" "$(APP_ID).flatpak" --clobber
	@echo "==> Upload complete!"
