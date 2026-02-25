# frozen_string_literal: true

require_relative 'test_helper'

class IntegrationGenerationTest < Minitest::Test
  TAG = ENV.fetch('LLAMA_CPP_TAG', 'b6124').freeze

  def test_generated_bindings_cover_all_llama_functions
    skip 'set RUN_LLAMA_INTEGRATION=1 to run integration test' unless ENV['RUN_LLAMA_INTEGRATION'] == '1'

    Dir.mktmpdir('llama-bindgen') do |dir|
      output = File.join(dir, 'llama_bindings.rb')
      config = LlamaCppFfiGenerator::Config.new(tag: TAG, workdir: dir, output: output)
      LlamaCppFfiGenerator::Generator.new(config).call

      source_header = File.join(dir, "llama.cpp-#{TAG}", 'include/llama.h')
      header_text = File.read(source_header)
      ruby_text = File.read(output)

      missing = LlamaCppFfiGenerator::ApiCoverage.missing_functions(
        header_text: header_text,
        ruby_text: ruby_text
      )

      assert_empty missing, "Missing bindings for #{missing.to_a.sort.join(', ')}"
    end
  end
end
