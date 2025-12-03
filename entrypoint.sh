#!/usr/bin/env bash
# shellcheck disable=SC1091
set -xeuo pipefail
env

#Requires associative array support
if [ -z "${BASH_VERSION:-}" ] || [ "${BASH_VERSION%%.*}" -lt 4 ]; then
    echo "This script requires Bash version 4.0 or higher"
    exit 1
fi


REPO_NAME=${REPO_NAME:-"$(git config --get remote.origin.url | cut -d '/' -f 2 | cut -d '.' -f 1)"}
REPO_NAME=${REPO_NAME:-"$(echo "$GITHUB_REPOSITORY" | cut -d '/' -f 2)"}
PKG_VERSION=${PKG_VERSION:-$(git describe --tags --always)}

# Use prebuilt builder images instead of building locally
# e.g. ghcr.io/aerospike/asadm-builder-el8:<tag>
: "${USE_REMOTE_BUILDER_IMAGES:=false}"

# Prefix for prebuilt builder images; override from CI
# We'll form: ${BUILDER_IMAGE_PREFIX}-${distro}:${PKG_VERSION}
: "${BUILDER_IMAGE_PREFIX:=ghcr.io/aerospike/${REPO_NAME}-builder}"


if [ "${TEST_MODE:-"false"}" = "true" ]; then
  BASE_COMMON_DIR="$(pwd)/.github/packaging/common/test/"
  BASE_PROJECT_DIR="$(pwd)/.github/packaging/project/test/"
else
  BASE_COMMON_DIR="$(pwd)/.github/packaging/common/"
  BASE_PROJECT_DIR="$(pwd)/.github/packaging/project/"
fi

declare -A distro_to_image
distro_to_image["el8"]="redhat/ubi8:8.10"
distro_to_image["el9"]="redhat/ubi9:9.6"
distro_to_image["el10"]="redhat/ubi10:10.0"
distro_to_image["amzn2023"]="amazonlinux:2023"
distro_to_image["debian12"]="debian:bookworm"
distro_to_image["debian13"]="debian:trixie"
distro_to_image["ubuntu20.04"]="ubuntu:20.04"
distro_to_image["ubuntu22.04"]="ubuntu:22.04"
distro_to_image["ubuntu24.04"]="ubuntu:24.04"

declare -A repo_to_package
repo_to_package["asconfig"]="asconfig"
repo_to_package["aerospike-admin"]="asadm"
repo_to_package["aerospike-benchmark"]="asbench"
repo_to_package["aerospike-tools-backup"]="asbackup"
repo_to_package["aql"]="aql"
repo_to_package["aerospike-tools"]="tools"


export PACKAGE_NAME=${repo_to_package["$REPO_NAME"]}



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

    if [ "${USE_REMOTE_BUILDER_IMAGES}" = "true" ]; then
      # Use prebuilt builder images from registry
      IMAGE="${BUILDER_IMAGE_PREFIX}-${BUILD_DISTRO}:${PKG_VERSION}"
      echo "Using prebuilt builder image: $IMAGE"
      docker pull "$IMAGE"

      # Make sure this matches what execute_build_image currently does:
      # - mount repo
      # - put artifacts in ../dist/$BUILD_DISTRO
      export BUILD_DISTRO="$BUILD_DISTRO"
      docker run \
        -v "$(realpath ../dist)":/tmp/output \
        -e BUILD_DISTRO \
        "$IMAGE" 
      ls -laht ../dist

      # If your existing execute_build_image copies artifacts to ../dist/$BUILD_DISTRO,
      # either keep that behavior inside the image, or add a cp step here.
    else
      # Old behavior: assume image was just built locally by -c
      execute_build_image "$BUILD_DISTRO"
    fi
fi
