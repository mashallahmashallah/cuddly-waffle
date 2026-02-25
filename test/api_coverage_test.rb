# frozen_string_literal: true

require_relative 'test_helper'

class ApiCoverageTest < Minitest::Test
  def test_detects_missing_bindings
    header = <<~H
      int llama_init();
      void llama_shutdown();
    H

    generated = <<~R
      attach_function :llama_init, [], :int
    R

    missing = LlamaCppFfiGenerator::ApiCoverage.missing_functions(
      header_text: header,
      ruby_text: generated
    )

    assert_equal ['llama_shutdown'], missing.to_a
  end

  def test_parses_alias_style_attach_function
    header = 'int llama_backend_init();'
    generated = 'attach_function :backend_init, :llama_backend_init, [], :void'

    missing = LlamaCppFfiGenerator::ApiCoverage.missing_functions(
      header_text: header,
      ruby_text: generated
    )

    assert_empty missing
  end
end
