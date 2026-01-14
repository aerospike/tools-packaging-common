#!/usr/bin/env bash
set -xeuo pipefail
DISTRO="$1"
REPO_NAME="$2"
PKG_VERSION="$3"
PACKAGE_NAME="$4"
env
git fetch --unshallow --tags --force 2>/dev/null || git fetch --tags --force
.github/packaging/common/example-test.sh "$DISTRO" "$REPO_NAME" "$PKG_VERSION" "$PACKAGE_NAME"
