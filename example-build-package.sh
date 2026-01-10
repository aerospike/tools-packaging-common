#!/usr/bin/env bash
DISTRO=${1:-}
# This repo is intended to be invoked on Linux with git and docker installed
# Your working directory should be the root of the git repository

# Project specific code goes in
#  project-example/build_package.sh (compile)
#  project-example/install_deps.sh (install dependencies necessary to compile the project-example)
#  project-example/test/test_execute.bats (test code to install and validate the produced package installed from artifactory)




# To build the packaging container, use
.github/packaging/common/entrypoint.sh -c -d "$DISTRO"

# To execute the build, use
.github/packaging/common/entrypoint.sh -e -d "$DISTRO"

# This will produce packages in ../dist relative to your current working directory
# $ ls ../dist/$DISTRO
# aerospike-asconfig-0.19.0-173-gde57889.$DISTRO.aarch64.rpm
