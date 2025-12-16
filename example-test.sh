#!/usr/bin/env bash
DISTRO=${1:-"el9"}

GIT_REPO_NAME=$(git config --get remote.origin.url | rev | cut -d '.' -f 2 | rev | cut -d '/' -f 2)
REPO_NAME=${2:-"$GIT_REPO_NAME"}
PKG_VERSION=${3:-$(git describe --tags --always --abbrev=7)}
PACKAGE_NAME=${4:-"$REPO_NAME"}
set -x
# You can execute this README by replacing the following with your email and your JFrog token:
# JF_USERNAME='ghaywood@aerospike.com' JF_TOKEN='xxxxxxxxxxxxxxxxxx' .github/packaging/common/test/README-test.sh
# This assumes the current commit has already been built and is available on JFrog


#Testing a package is available from the repository and can be executed:
JF_USERNAME=${JF_USERNAME:-"You must provide your JFrog username"}
JF_TOKEN=${JF_TOKEN:-"You must provide your JFrog token"}

#This commit should have already been pushed, so the action has built it and uploaded it to JFrog
export PKG_VERSION
export PACKAGE_NAME

if [ "${GITHUB_ACTIONS:-}" = "true" ] && [ "${USE_REMOTE_BUILDER_IMAGES:-false}" = "true" ]; then
  echo "Use pre-built image $image"
  TEST_MODE=true .github/packaging/common/test/entrypoint.sh -e -d "$DISTRO"
else
  #Build the test container and install the current version of asconfig from JFrog
  # -d specifies the distro to test
  # build test runner
  TEST_MODE=true .github/packaging/common/test/entrypoint.sh -c -d "$DISTRO"
  # Execute the test runner
  TEST_MODE=true .github/packaging/common/test/entrypoint.sh -e -d "$DISTRO"
fi
