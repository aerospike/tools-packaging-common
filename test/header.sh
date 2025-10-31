#!/usr/bin/env bash
set -xeuo pipefail

function install_deb_package() {
  apt -y install "aerospike-$PACKAGE_NAME"="$PKG_VERSION"
}

function install_rpm_package() {
  RPM_FORMAT="$(echo "$PKG_VERSION" | tr '-' '_')"
  dnf install -y "aerospike-$PACKAGE_NAME-$RPM_FORMAT-1.$(uname -m)"
}

function install_deps () {
  install_deps_"$1"
    if command -v apt;
    then
      install_deb_package
    else
      install_rpm_package
    fi
}

