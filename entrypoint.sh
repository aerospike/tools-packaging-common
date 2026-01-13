#!/usr/bin/env bash
# shellcheck disable=SC1091
set -xeuo pipefail
env

#Requires associative array support
if [ -z "${BASH_VERSION:-}" ] || [ "${BASH_VERSION%%.*}" -lt 4 ]; then
    echo "This script requires Bash version 4.0 or higher"
    exit 1
fi

declare -A distro_to_image
distro_to_image["el8"]="redhat/ubi8:8.10"
distro_to_image["el9"]="redhat/ubi9:9.6"
distro_to_image["el10"]="redhat/ubi10:10.0"
distro_to_image["amzn2023"]="amazonlinux:2.0.20251208.0"
distro_to_image["debian12"]="debian:bookworm-20230411"
distro_to_image["debian13"]="debian:trixie-20251020"
distro_to_image["ubuntu20.04"]="ubuntu:focal-20210723"
distro_to_image["ubuntu22.04"]="ubuntu:jammy-20231004"
distro_to_image["ubuntu24.04"]="ubuntu:noble-20231126.1"

declare -A distro_to_test_image
distro_to_test_image["el8"]="redhat/ubi8"
distro_to_test_image["el9"]="redhat/ubi9"
distro_to_test_image["el10"]="redhat/ubi10"
distro_to_test_image["amzn2023"]="amazonlinux:2023"
distro_to_test_image["debian12"]="debian:bookworm"
distro_to_test_image["debian13"]="debian:trixie"
distro_to_test_image["ubuntu20.04"]="ubuntu:20.04"
distro_to_test_image["ubuntu22.04"]="ubuntu:22.04"
distro_to_test_image["ubuntu24.04"]="ubuntu:24.04"

declare -A repo_to_package
repo_to_package["asconfig"]="asconfig"
repo_to_package["aerospike-admin"]="asadm"
repo_to_package["aerospike-benchmark"]="asbench"
repo_to_package["aerospike-tools-backup"]="asbackup"
repo_to_package["aql"]="aql"
repo_to_package["aerospike-tools"]="tools"

# Git inside containers may refuse to operate on bind mounts ("dubious ownership")
if command -v git >/dev/null 2>&1; then
  git config --global --add safe.directory "$(pwd)" || true
  # Optional: if you always mount under /opt/<repo>, allow all under /opt
  git config --global --add safe.directory /opt/* || true
fi

REPO_NAME=${REPO_NAME:-"${GITHUB_REPOSITORY##*/}"}
if [ -z "${REPO_NAME}" ] && command -v git >/dev/null 2>&1; then
  REPO_NAME="$(git config --get remote.origin.url | cut -d '/' -f 2 | cut -d '.' -f 1)"
fi

PKG_VERSION=${PKG_VERSION:-$(git describe --tags --always --abbrev=7)}
IMAGE_TAG=${IMAGE_TAG:-$PKG_VERSION}

export PACKAGE_NAME=${repo_to_package["$REPO_NAME"]}
export IMAGE_TAG PKG_VERSION

# Use prebuilt builder images instead of building locally
# e.g. artifact.aerospike.io/database-container-dev-local/aerospike-tools/<tool-name>-pkg-builder-el9-x86_64
: "${BUILD_BUILDER_IMAGES:=false}"

# Prefix for prebuilt builder images; override from CI
: "${BUILDER_IMAGE_PREFIX:-}"
: "${ARCH:=$(uname -m)}"
export ARCH BUILD_BUILDER_IMAGES
export BUILDER_IMAGE_PREFIX

if [ "${TEST_MODE:-"false"}" = "true" ]; then
  BASE_COMMON_DIR="$(pwd)/.github/packaging/common/test"
  BASE_PROJECT_DIR="$(pwd)/.github/packaging/project/test"
else
  BASE_COMMON_DIR="$(pwd)/.github/packaging/common"
  BASE_PROJECT_DIR="$(pwd)/.github/packaging/project"
fi

if [ -f "$BASE_PROJECT_DIR/build_package.sh" ]; then
  source "$BASE_PROJECT_DIR/build_package.sh"
fi

source "$BASE_COMMON_DIR/build_container.sh"

INSTALL=false
RUN_TESTS=false
INSTALL=false
BUILD_INTERNAL=false
BUILD_CONTAINERS=false
EXECUTE_BUILD=false
BUILD_DISTRO=${BUILD_DISTRO:-"all"}

while getopts "tbced:" opt; do
    case ${opt} in
        t )
            RUN_TESTS=true
            ;;
        b )
            BUILD_INTERNAL=true
            ;;
        c )
            BUILD_CONTAINERS=true
            ;;
        e )
            EXECUTE_BUILD=true
            ;;
        d )
            BUILD_DISTRO="$OPTARG"
            ;;
        * )
            ;;
    esac
done
shift $((OPTIND -1))

if [ "$INSTALL" = false ] && [ "$BUILD_INTERNAL" = false ] && [ "$BUILD_CONTAINERS" = false ] && [ "$EXECUTE_BUILD" = false ] && [ "$RUN_TESTS" = false ];
then
    echo "Usage:
    -t ( run test cases )
    -i ( install dependencies )
    -b ( compile and package project )
    -c ( build container -d \$DISTRO )
    -e ( execute prepared builder image and produce artifact in ../dist/\$DISTRO )
    -d [ el8 el9 el10 amazon2023 debian12 debian13 ubuntu20.04 ubuntu22.04 ubuntu24.04 ]" 1>&2
    exit 1
fi
export ENV_DISTRO
if grep -q 20.04 /etc/os-release; then
  ENV_DISTRO="ubuntu20.04"
elif grep -q 22.04 /etc/os-release; then
  ENV_DISTRO="ubuntu22.04"
elif grep -q 24.04 /etc/os-release; then
  ENV_DISTRO="ubuntu24.04"
elif grep -q "platform:el8" /etc/os-release; then
  ENV_DISTRO="el8"
elif grep -q "platform:el9" /etc/os-release; then
  ENV_DISTRO="el9"
elif grep -q "platform:el10" /etc/os-release; then
  ENV_DISTRO="el10"
elif grep -q "amazon_linux:2023" /etc/os-release; then
  ENV_DISTRO="amzn2023"
elif grep -q "bookworm" /etc/os-release; then
  ENV_DISTRO="debian12"
elif grep -q "trixie" /etc/os-release; then
  ENV_DISTRO="debian13"
else
  cat /etc/os-release
  echo "os not supported"
fi


if [ "$RUN_TESTS" = "true" ]; then
  bats .github/packaging/project/test/test_execute.bats
  exit $?
elif [ "$BUILD_INTERNAL" = "true" ]; then
  build_packages
elif [ "$BUILD_CONTAINERS" = "true" ]; then
  build_container "$BUILD_DISTRO"
elif [ "$EXECUTE_BUILD" = "true" ]; then
    echo "building package for $BUILD_DISTRO"
    execute_build_image "$BUILD_DISTRO"
fi
