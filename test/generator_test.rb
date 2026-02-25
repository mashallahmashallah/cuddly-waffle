# frozen_string_literal: true

require_relative 'test_helper'

class GeneratorTest < Minitest::Test
  def test_generator_runs_fetch_then_bindgen
    calls = []

    fetcher = Class.new do
      define_method(:initialize) { |**opts| @opts = opts }
      define_method(:fetch) { '/tmp/source' }
    end

    bindgen = Class.new do
      define_method(:initialize) { |**opts| @opts = opts; (Thread.current[:calls] ||= []) << opts }
      define_method(:run) { true }
    end

    with_replaced_constant(LlamaCppFfiGenerator, :ReleaseFetcher, fetcher) do
      with_replaced_constant(LlamaCppFfiGenerator, :BindgenRunner, bindgen) do
        Thread.current[:calls] = calls
        cfg = LlamaCppFfiGenerator::Config.new(tag: 'v1.0.0', workdir: 'tmp', output: 'out.rb')
        out = LlamaCppFfiGenerator::Generator.new(cfg).call

        assert_equal 'out.rb', out
        assert_equal 1, calls.size
        assert_equal '/tmp/source', calls.first[:source_dir]
        assert_equal 'out.rb', calls.first[:output]
      end
    end
  end

  private

  def with_replaced_constant(mod, const_name, value)
    original = mod.const_get(const_name)
    mod.send(:remove_const, const_name)
    mod.const_set(const_name, value)
    yield
  ensure
    mod.send(:remove_const, const_name)
    mod.const_set(const_name, original)
  end
end
