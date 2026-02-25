# frozen_string_literal: true

module LlamaCppFfiGenerator
  DEFAULT_TAG = 'b6124'

  Config = Struct.new(
    :tag,
    :workdir,
    :output,
    :module_name,
    :library_name,
    :header_path,
    keyword_init: true
  ) do
    def initialize(**kwargs)
      super
      self.tag ||= LlamaCppFfiGenerator::DEFAULT_TAG
      self.workdir ||= 'tmp/releases'
      self.output ||= File.join('lib', 'llama', 'generated_bindings.rb')
      self.module_name ||= 'Llama'
      self.library_name ||= 'llama'
      self.header_path ||= 'include/llama.h'
    end
  end
end
