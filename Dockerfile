# syntax=docker/dockerfile:1.7

ARG BASE_IMAGE=gcc:15.2

FROM ${BASE_IMAGE} AS builder
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG DEBIAN_FRONTEND=noninteractive
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && \
    apt-get install -y --no-install-recommends cmake git ninja-build ca-certificates && \
    rm -rf /var/lib/apt/lists/*

ARG GIT_REPO=https://github.com/example/project.git
ARG GIT_REF=main
ARG SOURCE_DIR=/src
ARG BUILD_DIR=/build
ARG CMAKE_GENERATOR=Ninja
ARG CMAKE_CONFIGURE_ARGS="-DCMAKE_BUILD_TYPE=Release"
ARG CMAKE_BUILD_ARGS="--parallel"
ARG BUILD_TARGET=""
ARG EXPORT_PATH=/build

WORKDIR /
# Fetch source via BuildKit ADD for cache-friendly layers. Keep .git so we can checkout refs.
ADD --keep-git-dir=true ${GIT_REPO} ${SOURCE_DIR}

WORKDIR ${SOURCE_DIR}
RUN git checkout --detach "${GIT_REF}" && git submodule update --init --recursive

RUN --mount=type=cache,target=${BUILD_DIR},sharing=locked \
    cmake -S "${SOURCE_DIR}" -B "${BUILD_DIR}" -G "${CMAKE_GENERATOR}" ${CMAKE_CONFIGURE_ARGS} && \
    cmake --build "${BUILD_DIR}" ${BUILD_TARGET:+--target "${BUILD_TARGET}"} ${CMAKE_BUILD_ARGS} && \
    mkdir -p /out && cp -a "${EXPORT_PATH}"/. /out/

FROM scratch AS artifact
COPY --link --from=builder /out/ /
