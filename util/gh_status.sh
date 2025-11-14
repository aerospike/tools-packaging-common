#!/usr/bin/env bash
REPOSITORIES=${1:-"aerospike/asconfig aerospike/aql aerospike/aerospike-tools-backup aerospike/aerospike-benchmark aerospike/aerospike-admin"}

if ! command -v gh >/dev/null 2>&1; then
  echo "GitHub cli not installed"
else
  for TOOL_REPO in $REPOSITORIES; do
    echo "$TOOL_REPO":
    gh run list --workflow "build-artifacts.yml" --limit 1 --repo "$TOOL_REPO"
  done
fi

