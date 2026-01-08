#!/usr/bin/env bash
# shellcheck disable=SC2154
set -xeuo pipefail

function build_container() {
  local distro=$1
  local image="${PACKAGE_NAME}-pkg-tester-${distro}-${ARCH}"

  docker build \
    --progress=plain \
    --build-arg=BASE_IMAGE="${distro_to_test_image["$distro"]}" \
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

  # Default local image name
  local image="${PACKAGE_NAME}-pkg-tester-${BUILD_DISTRO}-${ARCH}:${PKG_VERSION}"

  docker run \
    -e BUILD_DISTRO \
    -v "$(realpath ../dist)":/tmp/output \
    "$image"
}
