#!/usr/bin/env bash
# shellcheck disable=SC2154
set -xeuo pipefail

function build_container() {
  local distro=$1
  local image="${PACKAGE_NAME}-pkg-builder-${distro}-${ARCH}"
  local pushImage="${BUILD_BUILDER_IMAGES:-false}"
  local prefix="${BUILDER_IMAGE_PREFIX:-}"
  local fullImage="${prefix}${image}"


  docker build --progress=plain \
    --build-arg=BASE_IMAGE="${distro_to_image["$distro"]}" \
    --build-arg=ENV_DISTRO="$distro" \
    --build-arg=REPO_NAME="$REPO_NAME" \
    -t "${fullImage}:${IMAGE_TAG}" \
    -f .github/packaging/common/Dockerfile .
  jf docker tag "${fullImage}:${IMAGE_TAG}" "${fullImage}:latest"
  if [[ "${pushImage}" == "true" ]]; then
    jf docker push "${fullImage}:${IMAGE_TAG}"
    jf docker push "${fullImage}:latest"
  fi	  
}

function execute_build_image() {
  local distro=$1	
  export BUILD_DISTRO="$distro"

  # When true, use prebuilt images from a registry; otherwise use local images
  local image="${PACKAGE_NAME}-pkg-builder-${distro}-${ARCH}"
  local prefix="${BUILDER_IMAGE_PREFIX:-}"
  local fullImage="${prefix}${image}"

  docker run \
    -e BUILD_DISTRO \
    -v "$(realpath ../dist)":/tmp/output \
    "$fullImage:latest"

  ls -laht ../dist
}
