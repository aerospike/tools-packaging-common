#!/usr/bin/env bash
# shellcheck disable=SC2154
set -xeuo pipefail

function build_container() {
  local distro=$1
  local image="${PACKAGE_NAME}-pkg-tester-${distro}-${ARCH}"

  docker build \
    --progress=plain \
    --build-arg=BASE_IMAGE="${distro_to_test_image[$distro]}" \
    --build-arg=ENV_DISTRO="$distro" \
    --build-arg=PKG_VERSION="$PKG_VERSION" \
    --build-arg=JF_USERNAME="$JF_USERNAME" \
    --build-arg=JF_TOKEN="$JF_TOKEN" \
    --build-arg=PACKAGE_NAME="$PACKAGE_NAME" \
    --build-arg=REPO_NAME="$REPO_NAME" \
    -t "${image}:${PKG_VERSION}" \
    -f .github/packaging/common/test/Dockerfile .

  docker tag "${image}:$PKG_VERSION" "${image}:latest"
}

function execute_build_image() {
  export BUILD_DISTRO="$1"
  # When true, use prebuilt images from a registry; otherwise use local images
  local use_remote="${USE_REMOTE_BUILDER_IMAGES:-false}"

  # Default local image name
  local local_image="${PACKAGE_NAME}-pkg-tester-${BUILD_DISTRO}-${ARCH}:${PKG_VERSION}"

  # Optional remote prefix, e.g. ghcr.io/aerospike/<package_name>-build
  local prefix="${BUILDER_IMAGE_PREFIX:-}"

  local image

  if [ "$use_remote" = "true" ]; then
    # If no prefix is set, fall back to local naming (so nothing breaks)
    if [ -n "$prefix" ]; then
      image="${prefix}-${BUILD_DISTRO}-${ARCH}:${PKG_VERSION}"
    else
      image="$local_image"
    fi

    echo "Using prebuilt builder image: $image"
    docker pull "$image"
  else
    image="$local_image"
  fi
  docker run "$image"
}
