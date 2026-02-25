# llama_cpp_ffi_generator

`llama_cpp_ffi_generator` is a Ruby gem that ships a `Llama` module wrapping the `llama.cpp` C API through FFI.

The FFI file (`lib/llama/generated_bindings.rb`) is generated from a **pinned llama.cpp source release** using [`ruby-bindgen`](https://github.com/ruby-rice/ruby-bindgen) during development/build time.

## Design

- Runtime consumers only need this gem + `ffi`.
- `ruby-bindgen` is a development dependency used to regenerate bindings.
- `Gemfile` points `ruby-bindgen` at the upstream git repo so generation uses the latest source.
- The generated bindings are committed so installing the gem does not require running bindgen.

## Runtime usage

```ruby
require 'llama'

# Example c-api call from generated bindings
count = Llama.llama_max_devices
puts count
```

By default bindings load `ffi_lib 'llama'`. Set `LLAMA_CPP_LIB` if needed:

```bash
LLAMA_CPP_LIB=/path/to/libllama.so ruby your_script.rb
```

## Regenerate bindings from llama.cpp

Default pinned release tag is `b6124`.

```bash
bundle exec rake bindings:generate
```

Choose a specific tag:

```bash
bundle exec rake "bindings:generate[v1.0.0]"
# or
LLAMA_CPP_TAG=v1.0.0 bundle exec rake bindings:generate
```

You can also invoke the executable directly:

```bash
bundle exec llama_cpp_ffi_generator --tag b6124 --output lib/llama/generated_bindings.rb --module-name Llama
```

## Build checks

```bash
bundle exec rake build
```

`rake build` verifies generated bindings exist and include `llama_*` functions, then runs tests.

## Tests

```bash
bundle exec rake test
```

Optional integration test (downloads llama.cpp and runs ruby-bindgen end-to-end):

```bash
RUN_LLAMA_INTEGRATION=1 LLAMA_CPP_TAG=b6124 bundle exec ruby -Itest test/integration_generation_test.rb
```


Optional runtime chat smoke test (requires local llama library + tiny GGUF model):

```bash
RUN_LLAMA_CHAT_INTEGRATION=1 \
LLAMA_CPP_LIB=/path/to/libllama.so \
LLAMA_MODEL_PATH=/path/to/tiny.gguf \
  bundle exec ruby -Itest test/llama_chat_integration_test.rb
```

This test verifies a real model can be loaded through the generated `Llama` FFI API and can decode/sample a chat turn.

Optional **stories260K llama2c conversion** integration test (modeled after llama.cpp CI):

```bash
RUN_STORIES260K_INTEGRATION=1 \
LLAMA_CPP_BUILD_DIR=build \
  bundle exec ruby -Itest test/stories260k_integration_test.rb
```

This test downloads `tok512.bin` and `stories260K.bin` from `karpathy/tinyllamas`, converts the llama2c checkpoint to GGUF with `llama-convert-llama2c-to-ggml`, then runs `llama-completion` with prompt `"One day, Lily met a Shoggoth"` and asserts non-empty generated continuation.

## CI

GitHub Actions workflow (`.github/workflows/ci.yml`) runs unit + integration tests with all integration flags enabled. It prepares `stories260K.gguf` once in a dedicated job and publishes it as a reusable workflow artifact consumed by the test job.

