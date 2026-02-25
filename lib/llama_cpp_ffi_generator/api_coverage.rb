# frozen_string_literal: true

require 'set'

module LlamaCppFfiGenerator
  module ApiCoverage
    module_function

    def header_functions(header_text)
      header_text.scan(/\b(llama_[a-zA-Z0-9_]+)\s*\(/).flatten.to_set
    end

    def generated_functions(ruby_text)
      direct = ruby_text.scan(/attach_function\s+:?(llama_[a-zA-Z0-9_]+)/).flatten
      aliases = ruby_text.scan(/attach_function\s+:([a-zA-Z0-9_]+)\s*,\s*:?(llama_[a-zA-Z0-9_]+)/).map(&:last)
      Set.new(direct + aliases)
    end

    def missing_functions(header_text:, ruby_text:)
      header_functions(header_text) - generated_functions(ruby_text)
    end
  end
end
