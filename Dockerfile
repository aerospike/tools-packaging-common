ARG BASE_IMAGE
FROM $BASE_IMAGE
ARG ENV_DISTRO
ENV ENV_DISTRO=${ENV_DISTRO}
ARG REPO_NAME
ENV REPO_NAME=${REPO_NAME}
SHELL ["/bin/bash", "-euox", "pipefail", "-c"]

#noop for non-golang projects
ENV GOROOT=/opt/golang/go/

#noop for redhat enviornments
ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /opt/

# Copy ONLY the packaging scripts needed to install deps
COPY .github/packaging .github/packaging
RUN source .github/packaging/common/header.sh && \
    source .github/packaging/project/install_deps.sh && \
    install_deps "${ENV_DISTRO}"

ENTRYPOINT [".github/packaging/common/entrypoint.sh"]
CMD ["-b"]
