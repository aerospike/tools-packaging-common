#!/usr/bin/env bash
# shellcheck disable=SC2154
set -xeuo pipefail

function build_container() {
  docker build --progress=plain \
    --build-arg=BASE_IMAGE="${distro_to_image["$1"]}" \
    --build-arg=ENV_DISTRO="$1" \
    --build-arg=REPO_NAME="$REPO_NAME" \
    -t "$PACKAGE_NAME-pkg-builder-$1-${ARCH}":"$PKG_VERSION" \
    -f .github/packaging/common/Dockerfile .
}

function execute_build_image() {
  export BUILD_DISTRO="$1"

  # When true, use prebuilt images from a registry; otherwise use local images
  local use_remote="${USE_REMOTE_BUILDER_IMAGES:-false}"

  # Default local image name
  local local_image="${PACKAGE_NAME}-pkg-builder-${BUILD_DISTRO}-${ARCH}:${PKG_VERSION}"

  # Optional remote prefix, e.g. ghcr.io/aerospike/<package_name>-build
  local prefix="${BUILDER_IMAGE_PREFIX:-}"

  local image

  if [ "$use_remote" = "true" ]; then
    # If no prefix is set, fall back to local naming (so nothing breaks)
    if [ -n "$prefix" ]; then
      image="${prefix}-${BUILD_DISTRO}-${ARCH}:latest"
    else
      image="$local_image"
    fi

    echo "Using prebuilt builder image: $image"
    docker pull "$image"
  else
    image="$local_image"
  fi

  docker run \
    -e BUILD_DISTRO \
    -v "$(realpath ../dist)":/tmp/output \
    "$image"

  ls -laht ../dist
}
