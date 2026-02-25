# syntax=docker/dockerfile:1.7

ARG BASE_IMAGE=gcc:15.2

FROM ${BASE_IMAGE} AS base
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG DEBIAN_FRONTEND=noninteractive
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && \
    apt-get install -y --no-install-recommends cmake git ninja-build ca-certificates ccache && \
    rm -rf /var/lib/apt/lists/*

FROM base AS zendnn-builder

ARG ZENDNN_GIT_REPO=https://github.com/amd/ZenDNN.git
ARG ZENDNN_GIT_REF=main
ARG ZENDNN_SOURCE_DIR=/zendnn-src
ARG ZENDNN_BUILD_DIR=/zendnn-build
ARG ZENDNN_INSTALL_DIR=/opt/zendnn
ARG ZENDNN_CMAKE_GENERATOR=Ninja
ARG ZENDNN_CMAKE_CONFIGURE_ARGS="-DCMAKE_BUILD_TYPE=Release"
ARG ZENDNN_CMAKE_BUILD_ARGS="--parallel"

WORKDIR /
ADD --keep-git-dir=true ${ZENDNN_GIT_REPO} ${ZENDNN_SOURCE_DIR}

WORKDIR ${ZENDNN_SOURCE_DIR}
RUN set -eux; \
    if git checkout --detach "${ZENDNN_GIT_REF}"; then \
      :; \
    elif [[ "${ZENDNN_GIT_REF}" == "main" ]]; then \
      git checkout --detach master; \
    elif [[ "${ZENDNN_GIT_REF}" == "master" ]]; then \
      git checkout --detach main; \
    else \
      echo "error: unable to checkout ZenDNN ref '${ZENDNN_GIT_REF}'" >&2; \
      exit 1; \
    fi && \
    git submodule update --init --recursive

RUN cmake -S "${ZENDNN_SOURCE_DIR}" -B "${ZENDNN_BUILD_DIR}" \
    -G "${ZENDNN_CMAKE_GENERATOR}" \
    -DCMAKE_INSTALL_PREFIX="${ZENDNN_INSTALL_DIR}" \
    ${ZENDNN_CMAKE_CONFIGURE_ARGS} && \
    cmake --build "${ZENDNN_BUILD_DIR}" ${ZENDNN_CMAKE_BUILD_ARGS} && \
    cmake --install "${ZENDNN_BUILD_DIR}"

FROM base AS builder

ARG GIT_REPO=https://github.com/example/project.git
ARG GIT_REF=main
ARG SOURCE_DIR=/src
ARG BUILD_DIR=/build
ARG CMAKE_GENERATOR=Ninja
ARG CMAKE_CONFIGURE_ARGS="-DCMAKE_BUILD_TYPE=Release"
ARG CMAKE_BUILD_ARGS="--parallel"
ARG BUILD_TARGET=""
ARG EXPORT_PATH=/build
ARG ENABLE_EXTERNAL_ZENDNN=false
ARG ZENDNN_INSTALL_DIR=/opt/zendnn
ARG CCACHE_DIR=/ccache
ARG FBGEMM_INC=""

COPY --from=zendnn-builder ${ZENDNN_INSTALL_DIR} ${ZENDNN_INSTALL_DIR}
COPY --from=zendnn-builder /zendnn-src /external-zendnn-src

WORKDIR /
# Fetch source via BuildKit ADD for cache-friendly layers. Keep .git so we can checkout refs.
ADD --keep-git-dir=true ${GIT_REPO} ${SOURCE_DIR}

WORKDIR ${SOURCE_DIR}
RUN git checkout --detach "${GIT_REF}" && git submodule update --init --recursive

RUN if [[ "${ENABLE_EXTERNAL_ZENDNN}" == "true" ]]; then \
      if [[ -d "${SOURCE_DIR}/ggml/third_party/ZenDNN" ]]; then \
        rm -rf "${SOURCE_DIR}/ggml/third_party/ZenDNN" && \
        cp -a /external-zendnn-src "${SOURCE_DIR}/ggml/third_party/ZenDNN"; \
      elif [[ -d "${SOURCE_DIR}/third_party/ZenDNN" ]]; then \
        rm -rf "${SOURCE_DIR}/third_party/ZenDNN" && \
        cp -a /external-zendnn-src "${SOURCE_DIR}/third_party/ZenDNN"; \
      else \
        echo "warning: could not find bundled ZenDNN directory to replace"; \
      fi; \
    fi

ENV CMAKE_PREFIX_PATH=${ZENDNN_INSTALL_DIR}:${CMAKE_PREFIX_PATH}
ENV ZENDNNROOT=${ZENDNN_INSTALL_DIR}
ENV ZENDNN_ROOT=${ZENDNN_INSTALL_DIR}
ENV CCACHE_DIR=${CCACHE_DIR}
ENV FBGEMM_INC=${FBGEMM_INC}
ENV CCACHE_MAXSIZE=5G

RUN --mount=type=cache,target=${CCACHE_DIR},sharing=locked \
    eval "cmake -S \"${SOURCE_DIR}\" -B \"${BUILD_DIR}\" -G \"${CMAKE_GENERATOR}\" \
      -DCMAKE_C_COMPILER_LAUNCHER=ccache \
      -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
      ${CMAKE_CONFIGURE_ARGS}" && \
    cmake --build "${BUILD_DIR}" ${BUILD_TARGET:+--target "${BUILD_TARGET}"} ${CMAKE_BUILD_ARGS} && \
    ccache --show-stats && \
    mkdir -p /ccache-layer && cp -a "${CCACHE_DIR}"/. /ccache-layer/

RUN mkdir -p /out && cp -a "${EXPORT_PATH}"/. /out/

FROM scratch AS ccache
COPY --link --from=builder /ccache-layer/ /

FROM scratch AS artifact
COPY --link --from=builder /out/ /
