# Makefile for whereami
#
# Provides convenience targets for:
#  - Flatpak build, install, run, clean
#
# Requirements (host, outside Flatpak):
#  - Go toolchain (matching go.mod version)
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

.PHONY: all flatpak-build flatpak-bundle flatpak-install flatpak-run \
        flatpak-clean flatpak-rebuild release-update release-publish

all: flatpak-bundle

########################################
# Flatpak targets
########################################

# Build (no install) into $(FLATPAK_BUILDDIR)
flatpak-build:
	@echo "==> Flatpak build (no install)"
	flatpak-builder --ccache --force-clean $(FLATPAK_BUILDDIR) $(FLATPAK_MANIFEST)

# Build + install into user repo
flatpak-install:
	@echo "==> Flatpak build + install (user)"
	flatpak-builder --user --install --ccache --force-clean $(FLATPAK_BUILDDIR) $(FLATPAK_MANIFEST)

# Run installed Flatpak
flatpak-run:
	@echo "==> Running Flatpak $(APP_ID)"
	flatpak run $(APP_ID)

# Remove build artifacts (does not uninstall the app)
flatpak-clean:
	@echo "==> Cleaning Flatpak build dirs"
	rm -rf $(FLATPAK_BUILDDIR) $(FLATPAK_EXPORTDIR)
	rm -f $(APP_ID).flatpak

# Clean and create a fresh bundle
flatpak-rebuild:
	@echo "==> Cleaning and rebuilding Flatpak"
	$(MAKE) flatpak-clean
	$(MAKE) flatpak-bundle

# Export and create a distributable .flatpak bundle
flatpak-bundle:
	@echo "==> Creating Flatpak bundle"
	@mkdir -p $(FLATPAK_EXPORTDIR)
	flatpak-builder --ccache --repo=$(FLATPAK_EXPORTDIR) --force-clean $(FLATPAK_BUILDDIR) $(FLATPAK_MANIFEST)
	flatpak build-bundle $(FLATPAK_EXPORTDIR) $(APP_ID).flatpak $(APP_ID)
	@echo "==> Flatpak bundle created: $(APP_ID).flatpak"

# Update release metadata without committing it.
release-update:
	@if [ -z "$(TAG)" ]; then \
		echo "Error: TAG is required (for example: make release-update TAG=v0.1.11)"; \
		exit 1; \
	fi
	./scripts/release update "$(TAG)"

# Build and publish the version pinned in the committed manifest.
release-publish:
	./scripts/release publish $(if $(TAG),"$(TAG)")
