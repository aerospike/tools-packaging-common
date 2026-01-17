#!/usr/bin/env bash
# shellcheck disable=SC2154
set -xeuo pipefail

function build_container() {
	local distro="${1:?distro is required}"

	local image="${PACKAGE_NAME}-pkg-builder-${distro}-${ARCH}"
	local prefix="${BUILDER_IMAGE_PREFIX-}"
	local full_image="${prefix}${image}"

	local push_image="${BUILD_BUILDER_IMAGES:-false}"

	local tagged="${full_image}:${IMAGE_TAG}"
	local latest="${full_image}:latest"

	image_exists_local() {
		docker image inspect "$1" >/dev/null 2>&1
	}

	build_image() {
		docker build --progress=plain \
			--build-arg "BASE_IMAGE=${distro_to_image[$distro]}" \
			--build-arg "ENV_DISTRO=$distro" \
			--build-arg "REPO_NAME=$REPO_NAME" \
			-t "$tagged" \
			-f .github/packaging/common/Dockerfile .

		# Tag "latest" in the same registry namespace (jf wrapper ok even for local)
		docker tag "$tagged" "$latest"
	}

	pull_latest() {
		docker pull "$latest"
	}

	# 1) If we are explicitly building/pushing builder images, force a rebuild.
	if [[ $push_image == "true" ]]; then
		build_image
	else
		# 2) If we already have the image locally, use it.
		if image_exists_local "$tagged" || image_exists_local "$latest"; then
			: # already available locally
		else
			# 3) Not local: if prefix is set, try remote pull; otherwise build.
			if [[ -n $prefix ]]; then
				if pull_latest; then
					: # pulled successfully
				else
					echo "Remote image not found or pull failed: $latest. Building locally..." >&2
					build_image
				fi
			else
				build_image
			fi
		fi
	fi

	# 4) Push (only when requested and when remote prefix is configured)
	if [[ $push_image == "true" && -n $prefix ]]; then
		docker push "$tagged"
		docker push "$latest"
	fi
}

function execute_build_image() {
	local distro="${1:?distro is required}"
	export BUILD_DISTRO="$distro"

	local image="${PACKAGE_NAME}-pkg-builder-${distro}-${ARCH}"
	local prefix="${BUILDER_IMAGE_PREFIX-}"
	local full_image="${prefix}${image}"
	local tagged="${full_image}:${IMAGE_TAG}"

	# Ensure output dir exists and is mounted via an absolute path
	local out_dir
	out_dir="$(realpath ../dist)"
	mkdir -p "$out_dir"

	docker run --rm \
		-e BUILD_DISTRO \
		-e REPO_NAME="$REPO_NAME" \
		-v "$(pwd)":"/opt/${REPO_NAME}" \
		-v "${out_dir}:/tmp/output" \
		-w "/opt/${REPO_NAME}" \
		"$tagged"

	ls -laht "$out_dir"
}
