# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = 'llama_cpp_ffi_generator'
  spec.version       = '0.2.0'
  spec.summary       = 'Ruby llama.cpp C API wrapper generated with ruby-bindgen'
  spec.description   = 'Build-time generated Ruby FFI bindings for a pinned llama.cpp release, with a runtime Llama module wrapper.'
  spec.authors       = ['Codex']
  spec.email         = ['codex@example.com']
  spec.files         = Dir['lib/**/*.rb', 'exe/*', 'README.md']
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 3.1'

  spec.add_dependency 'ffi', '~> 1.16'

  spec.add_development_dependency 'minitest'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'ruby-bindgen'
end
