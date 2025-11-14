# GitHub Workflow Status Checker

You can use util/gh_status.sh to check the status of project(s) using build-artifacts.yml

## Prerequisites

- GitHub CLI tool must be installed and configured

## Usage

```bash
$ util/gh_status.sh aerospike/aerospike-benchmark
aerospike/aerospike-benchmark:
STATUS  TITLE                    WORKFLOW             BRANCH          EVENT  ID           ELAPSED  AGE
✓       update packaging common  build-artifacts.yml  dev/SERVER-216  push   19184093717  5m22s    about 2 days ago
```
