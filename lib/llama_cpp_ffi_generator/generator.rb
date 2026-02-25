# frozen_string_literal: true

module LlamaCppFfiGenerator
  class Generator
    def initialize(config)
      @config = config
    end

    def call
      source_dir = ReleaseFetcher.new(tag: config.tag, workdir: config.workdir).fetch
      BindgenRunner.new(
        source_dir: source_dir,
        output: config.output,
        module_name: config.module_name,
        library_name: config.library_name,
        header_path: config.header_path
      ).run
      config.output
    end

    private

    attr_reader :config
  end
end
