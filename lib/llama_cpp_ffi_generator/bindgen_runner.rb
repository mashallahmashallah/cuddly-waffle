# frozen_string_literal: true

require 'fileutils'
require 'open3'

module LlamaCppFfiGenerator
  class BindgenRunner
    def initialize(source_dir:, output:, module_name:, library_name:, header_path:)
      @source_dir = source_dir
      @output = output
      @module_name = module_name
      @library_name = library_name
      @header_path = header_path
    end

    def run
      FileUtils.mkdir_p(File.dirname(output))
      command = [
        'bundle', 'exec', 'ruby-bindgen',
        '--input', File.join(source_dir, header_path),
        '--output', output,
        '--module', module_name,
        '--library', library_name,
        '--prefix', 'llama_'
      ]

      stdout_str, stderr_str, status = Open3.capture3(*command)
      return if status.success?

      raise "ruby-bindgen failed (#{status.exitstatus})\nSTDOUT:\n#{stdout_str}\nSTDERR:\n#{stderr_str}"
    end

    private

    attr_reader :source_dir, :output, :module_name, :library_name, :header_path
  end
end
