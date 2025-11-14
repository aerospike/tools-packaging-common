#!/usr/bin/env bash
# shellcheck disable=SC2164
set -xeuo pipefail

pushd .github/packaging/common
git pull origin "$(git branch --show-current)"
popd
