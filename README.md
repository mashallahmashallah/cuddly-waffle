# Buildx + Bake CMake Builder

This repo includes a reusable Docker BuildKit pipeline for CMake projects hosted in Git.

## Files

- `Dockerfile`: multi-stage build that
  - fetches a Git repository source with `ADD` (cache-friendly layer),
  - checks out the requested ref with `git checkout`,
  - configures/builds with GCC + CMake,
  - exports selected build output into a final `scratch` image.
- `docker-bake.hcl`: parameterized Buildx Bake config for default and preset CPU/optimization variants, including optional external ZenDNN overrides for llama.cpp builds.

## Basic usage (bake)

```bash
docker buildx bake artifact \
  --set artifact.args.GIT_REPO=https://github.com/your-org/your-project.git \
  --set artifact.args.GIT_REF=main \
  --set artifact.args.CMAKE_CONFIGURE_ARGS="-DCMAKE_BUILD_TYPE=Release -DCMAKE_C_FLAGS='-O2' -DCMAKE_CXX_FLAGS='-O2'" \
  --set artifact.args.CMAKE_BUILD_ARGS="--parallel" \
  --set artifact.args.EXPORT_PATH=/build
```

## Presets

```bash
# Native CPU
docker buildx bake native-o3 --set native-o3.args.GIT_REPO=https://github.com/your-org/your-project.git

# Zen 4 tuned
docker buildx bake zen4-o3 --set zen4-o3.args.GIT_REPO=https://github.com/your-org/your-project.git
```


## Build llama.cpp with a specific external ZenDNN revision

You can precompile ZenDNN from `https://github.com/amd/ZenDNN` in a dedicated stage and then wire it into the `llama.cpp` build.

```bash
docker buildx bake artifact \
  --set artifact.args.GIT_REPO=https://github.com/ggerganov/llama.cpp.git \
  --set artifact.args.GIT_REF=master \
  --set artifact.args.ENABLE_EXTERNAL_ZENDNN=true \
  --set artifact.args.ZENDNN_GIT_REF=v5.0 \
  --set artifact.args.CMAKE_CONFIGURE_ARGS="-DCMAKE_BUILD_TYPE=Release -DGGML_ZENDNN=ON"
```

What this does:
- Builds ZenDNN in a separate Docker stage (`zendnn-builder`) at `ZENDNN_GIT_REF`.
- Installs ZenDNN to `/opt/zendnn` and exposes it through `CMAKE_PREFIX_PATH` + `ZENDNNROOT`.
- Replaces the bundled llama.cpp ZenDNN checkout (`ggml/third_party/ZenDNN` or `third_party/ZenDNN`) when `ENABLE_EXTERNAL_ZENDNN=true`.
- Uses `ccache` in the main project build (`CMAKE_*_COMPILER_LAUNCHER=ccache`) to accelerate repeat builds.

## Example: compile inside a container (without image build)

```bash
docker run --rm -v "$PWD":/usr/src/myapp -w /usr/src/myapp gcc:15.2 gcc -o myapp myapp.c
# or
docker run --rm -v "$PWD":/usr/src/myapp -w /usr/src/myapp gcc:15.2 make
```

## Notes

- The Dockerfile defaults to `BASE_IMAGE=gcc:15.2` and can be overridden via bake (`--set artifact.args.BASE_IMAGE=...`).
- `GIT_REPO` accepts Git URLs compatible with BuildKit `ADD` (including SSH URLs such as `git@git.example.com:foo/bar.git` when your builder is configured for SSH access).
- `CMAKE_CONFIGURE_ARGS` and `CMAKE_BUILD_ARGS` are raw argument strings, so you can pass arbitrary CMake flags at bake-time or CLI-time.
- The final `artifact` image is `scratch` and contains files copied from `EXPORT_PATH` (defaults to `/build`).


## GitHub Actions: build `llama.cpp` and upload artifact

A workflow is provided at `.github/workflows/build-llama-cpp.yml`.

- Trigger: **Actions → Build llama.cpp artifact with Docker Buildx → Run workflow**.
- Inputs: `llama_ref` (llama.cpp ref) and optional `zendnn_ref` (external ZenDNN ref).
- The workflow uses GitHub Actions-backed Buildx cache (`type=gha`, scope `llama-cpp`) to reuse layers across runs without requiring registry login.
- Docker builds use `ccache` compiler launchers and a dedicated `ccache` image stage that captures cache files as a standalone layer target.
- The workflow builds target `artifact`, extracts the filesystem, and uploads it as a GitHub Actions artifact.
- Artifact names are normalized from `llama_ref` so refs with `/`, `:`, or spaces upload reliably.
