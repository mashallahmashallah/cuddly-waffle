# frozen_string_literal: true

require_relative 'test_helper'
require 'open3'

class Stories260kIntegrationTest < Minitest::Test
  TOK_URL = 'https://huggingface.co/karpathy/tinyllamas/resolve/main/stories260K/tok512.bin'
  MODEL_URL = 'https://huggingface.co/karpathy/tinyllamas/resolve/main/stories260K/stories260K.bin'
  PROMPT = 'One day, Lily met a Shoggoth'

  def test_llama2c_stories260k_conversion_and_completion
    skip 'set RUN_STORIES260K_INTEGRATION=1 to run stories260k integration test' unless ENV['RUN_STORIES260K_INTEGRATION'] == '1'

    build_dir = ENV.fetch('LLAMA_CPP_BUILD_DIR', 'build')
    completion_bin = File.join(build_dir, 'bin', 'llama-completion')
    skip "missing completion binary: #{completion_bin}" unless File.executable?(completion_bin)

    gguf_path = ENV['STORIES260K_GGUF_PATH']
    if gguf_path && !gguf_path.empty?
      skip "artifact model file not found: #{gguf_path}" unless File.exist?(gguf_path)
      run_completion_assertions(completion_bin, gguf_path)
      return
    end

    convert_bin = File.join(build_dir, 'bin', 'llama-convert-llama2c-to-ggml')
    skip "missing converter binary: #{convert_bin}" unless File.executable?(convert_bin)

    Dir.mktmpdir('stories260k') do |dir|
      tok_path = File.join(dir, 'tok512.bin')
      llama2c_path = File.join(dir, 'stories260K.bin')
      gguf_path = File.join(dir, 'stories260K.gguf')

      download!(TOK_URL, tok_path)
      download!(MODEL_URL, llama2c_path)

      run_cmd!(
        convert_bin,
        '--copy-vocab-from-model', tok_path,
        '--llama2c-model', llama2c_path,
        '--llama2c-output-model', gguf_path
      )

      assert File.exist?(gguf_path), 'expected gguf model to be produced by conversion tool'
      assert_operator File.size(gguf_path), :>, 0, 'expected gguf model to be non-empty'

      run_completion_assertions(completion_bin, gguf_path)
    end
  end

  private

  def run_completion_assertions(completion_bin, gguf_path)
    output = run_cmd!(
      completion_bin,
      '-m', gguf_path,
      '-p', PROMPT,
      '-n', '120',
      '-c', '256'
    )

    normalized = output.gsub(/[^[:print:]\n]/, '').strip
    refute_empty normalized, 'expected non-empty completion output'
    assert_includes normalized, PROMPT, 'expected completion output to include prompt text'

    generated_tail = normalized.sub(PROMPT, '').strip
    refute_empty generated_tail, 'expected text generated after prompt'
    assert_match(/[[:alpha:]]/, generated_tail, 'expected generated continuation to contain alphabetic characters')
  end

  def download!(url, output_path)
    stdout, stderr, status = Open3.capture3('wget', '-q', '-O', output_path, url)
    return if status.success?

    raise "download failed for #{url}\nSTDOUT:\n#{stdout}\nSTDERR:\n#{stderr}"
  end

  def run_cmd!(*cmd)
    stdout, stderr, status = Open3.capture3(*cmd)
    return stdout + stderr if status.success?

    raise "command failed: #{cmd.join(' ')}\nSTDOUT:\n#{stdout}\nSTDERR:\n#{stderr}"
  end
end
