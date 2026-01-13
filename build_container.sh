#!/usr/bin/env bash
# shellcheck disable=SC2154
set -xeuo pipefail

function build_container() {
  local distro="${1:?distro is required}"

  local image="${PACKAGE_NAME}-pkg-builder-${distro}-${ARCH}"
  local prefix="${BUILDER_IMAGE_PREFIX:-}"
  local full_image="${prefix}${image}"

  local push_image="${BUILD_BUILDER_IMAGES:-false}"

  local tagged="${full_image}:${IMAGE_TAG}"
  local latest="${full_image}:latest"

  if [[ -z "$prefix" ]]; then
    docker build --progress=plain \
      --build-arg "BASE_IMAGE=${distro_to_image[$distro]}" \
      --build-arg "ENV_DISTRO=$distro" \
      --build-arg "REPO_NAME=$REPO_NAME" \
      -t "$tagged" \
      -f .github/packaging/common/Dockerfile .

    jf docker tag "$tagged" "$latest"
  else
    jf docker pull "$latest"
  fi

  if [[ "$push_image" == "true" && -n "$prefix" ]]; then
    jf docker push "$tagged"
    jf docker push "$latest"
  fi
}

function execute_build_image() {
  local distro="${1:?distro is required}"
  export BUILD_DISTRO="$distro"

  local image="${PACKAGE_NAME}-pkg-builder-${distro}-${ARCH}"
  local prefix="${BUILDER_IMAGE_PREFIX:-}"
  local full_image="${prefix}${image}"
  local latest="${full_image}:latest"

  # Ensure output dir exists and is mounted via an absolute path
  local out_dir
  out_dir="$(realpath ../dist)"
  mkdir -p "$out_dir"

  docker run --rm \
    -e BUILD_DISTRO \
    -e REPO_NAME="$REPO_NAME" \
    -v "$(pwd)":"/opt/${REPO_NAME}" \
    -v "${out_dir}:/tmp/output" \
    -w "/opt/${REPO_NAME}" \
    "$latest"

  ls -laht "$out_dir"
}
