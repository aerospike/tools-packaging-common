#!/usr/bin/env bash

function install_deps () {
  if type "install_deps_$1" > /dev/null 2>&1; then
    "install_deps_$1"
  fi
  if type "compile_deps_$1" > /dev/null 2>&1; then
    "compile_deps_$1"
  fi
}

