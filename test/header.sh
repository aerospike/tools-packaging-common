#!/usr/bin/env bash
set -xeuo pipefail


function install_deb_package() {
  apt -y install "aerospike-$PACKAGE_NAME"="$PKG_VERSION"
}

function install_rpm_package() {
  RPM_FORMAT="$(echo "$PKG_VERSION" | tr '-' '_')"
  dnf search --showduplicates aerospike-asadm
  dnf install -y "aerospike-$PACKAGE_NAME-$RPM_FORMAT-1.$(uname -m)"
  cat /etc/yum.repos.d/aerospike-el9-all.repo
}

function install_deps () {
  install_deps_"$1"
}

