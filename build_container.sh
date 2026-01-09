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
  if [[ "${pushImage}" == "true" ]]; then
    docker tag	"${fullImage}:${IMAGE_TAG}" "${fullImage}:latest"
    docker push "${fullImage}:${IMAGE_TAG}"
    docker push "${fullImage}:latest"
  fi	  
}

function execute_build_image() {
  export BUILD_DISTRO="$1"

  # When true, use prebuilt images from a registry; otherwise use local images
  local use_remote="${USE_REMOTE_BUILDER_IMAGES:-false}"

  # Default local image name
  local local_image="${PACKAGE_NAME}-pkg-builder-${BUILD_DISTRO}-${ARCH}:${IMAGE_TAG}"

  # Optional remote prefix, artifact.aerospike.io/database-container-dev-local/aerospike-tools/<package_name>-pkg-builder
  local prefix="${BUILDER_IMAGE_PREFIX:-}"

  local image

  if [ "$use_remote" = "true" ]; then
    # If no prefix is set, fall back to local naming (so nothing breaks)
    if [ -n "$prefix" ]; then
      image="${prefix}-${BUILD_DISTRO}-${ARCH}:${IMAGE_TAG}"
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
