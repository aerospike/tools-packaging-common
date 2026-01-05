#!/usr/bin/env bash
set -xeuo pipefail

#These functions execute retry loops because of the asynchronous updating behavior in JFrogs indexes
#https://aerospike.atlassian.net/browse/SERVER-470

function install_deb_package() {
  end=$((SECONDS + 300))
  while [ $SECONDS -lt $end ]; do
    if apt -y install "aerospike-$PACKAGE_NAME"="$PKG_VERSION"; then
      return 0
    fi
    echo "Installation failed, retrying in 10 seconds..."
    apt-get update || true
    sleep 10
  done
  echo "Installation failed after 5 minutes timeout"
  exit 1
}

function install_rpm_package() {
  RPM_FORMAT="$(echo "$PKG_VERSION" | tr '-' '_')"
  end=$((SECONDS + 300))
  while [ $SECONDS -lt $end ]; do
    if dnf install -y "aerospike-$PACKAGE_NAME-$RPM_FORMAT-1.$(uname -m)"; then
      return 0
    fi
    echo "Installation failed, retrying in 10 seconds..."
    dnf search --showduplicates aerospike-"$PACKAGE_NAME" || true
    dnf makecache --refresh || true
    sleep 10
  done
  echo "Installation failed after 5 minutes timeout"
  exit 1
}

function install_deps () {
  install_deps_"$1"
}
