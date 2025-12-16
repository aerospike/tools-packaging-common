#!/usr/bin/env bash
DISTRO=${1:-"el9"}

GIT_REPO_NAME=$(git config --get remote.origin.url | rev | cut -d '.' -f 2 | rev | cut -d '/' -f 2)
REPO_NAME=${2:-"$GIT_REPO_NAME"}
PKG_VERSION=${3:-$(git describe --tags --always --abbrev=7)}
set -x
# You can execute this README by replacing the following with your email and your JFrog token:
# JF_USERNAME='ghaywood@aerospike.com' JF_TOKEN='xxxxxxxxxxxxxxxxxx' .github/packaging/common/test/README-test.sh
# This assumes the current commit has already been built and is available on JFrog


#Testing a package is available from the repository and can be executed:
JF_USERNAME=${JF_USERNAME:-"You must provide your JFrog username"}
JF_TOKEN=${JF_TOKEN:-"You must provide your JFrog token"}

#This commit should have already been pushed, so the action has built it and uploaded it to JFrog
export PKG_VERSION

#Build the test container and install the current version of asconfig from JFrog
# -d specifies the distro to test
TEST_MODE=true .github/packaging/common/test/entrypoint.sh -c -d "$DISTRO"
#...

#Execute the test runner
docker run "$PACKAGE_NAME-pkg-tester-$DISTRO-$ARCH:$PKG_VERSION"

#...
#test_execute.bats
# ✓ can run asconfig
#
#1 test, 0 failures

