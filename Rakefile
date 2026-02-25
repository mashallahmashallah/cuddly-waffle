# frozen_string_literal: true

require 'rake/testtask'
require_relative 'lib/llama_cpp_ffi_generator'

namespace :bindings do
  desc 'Generate lib/llama/generated_bindings.rb from pinned llama.cpp release'
  task :generate, [:tag] do |_t, args|
    tag = args[:tag] || ENV['LLAMA_CPP_TAG'] || LlamaCppFfiGenerator::DEFAULT_TAG
    output = LlamaCppFfiGenerator::Build.generate_bindings!(tag: tag)
    puts "Generated bindings at #{output}"
  end
end

desc 'Build sanity check: ensure generated bindings exist and include llama_ symbols'
task 'bindings:verify' do
  path = File.join('lib', 'llama', 'generated_bindings.rb')
  abort "Missing generated bindings at #{path}. Run rake bindings:generate" unless File.exist?(path)

  ruby_text = File.read(path)
  functions = LlamaCppFfiGenerator::ApiCoverage.generated_functions(ruby_text)
  abort 'Generated bindings do not contain llama_* functions' if functions.empty?

  puts "Bindings verified (#{functions.size} llama_* functions found)."
end

Rake::TestTask.new(:test) do |t|
  t.libs << 'lib' << 'test'
  t.pattern = 'test/**/*_test.rb'
end

desc 'Project build task used before packaging'
task build: ['bindings:verify', :test]

task default: :test
