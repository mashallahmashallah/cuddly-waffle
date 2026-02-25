# frozen_string_literal: true

module LlamaCppFfiGenerator
  module Build
    module_function

    def generate_bindings!(tag: DEFAULT_TAG)
      config = Config.new(tag: tag)
      Generator.new(config).call
    end
  end
end
