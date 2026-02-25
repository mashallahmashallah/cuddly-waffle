# frozen_string_literal: true

require_relative 'test_helper'

class LlamaChatIntegrationTest < Minitest::Test
  def test_can_load_small_model_and_generate_chat_token
    skip 'set RUN_LLAMA_CHAT_INTEGRATION=1 to run llama chat integration test' unless ENV['RUN_LLAMA_CHAT_INTEGRATION'] == '1'

    require 'ffi'
    require_relative '../lib/llama'

    model_path = ENV['LLAMA_MODEL_PATH']
    skip 'set LLAMA_MODEL_PATH to a local tiny GGUF model file' if model_path.to_s.empty?
    skip "model file not found: #{model_path}" unless File.exist?(model_path)

    required = %i[
      llama_backend_init
      llama_backend_free
      llama_model_default_params
      llama_context_default_params
      llama_model_load_from_file
      llama_init_from_model
      llama_model_free
      llama_free
      llama_batch_init
      llama_batch_free
      llama_decode
      llama_tokenize
      llama_token_to_piece
      llama_sampler_chain_default_params
      llama_sampler_chain_init
      llama_sampler_chain_add
      llama_sampler_init_greedy
      llama_sampler_sample
      llama_sampler_free
    ]

    missing = required.reject { |fn| Llama.respond_to?(fn) }
    assert_empty missing, "Generated bindings missing required chat symbols: #{missing.join(', ')}"

    model = nil
    ctx = nil
    batch = nil
    chain = nil

    begin
      call_backend_init

      model_params = Llama.llama_model_default_params
      ctx_params = Llama.llama_context_default_params

      model = Llama.llama_model_load_from_file(model_path, model_params)
      refute_nil model, 'expected llama_model_load_from_file to return a model pointer'

      ctx = Llama.llama_init_from_model(model, ctx_params)
      refute_nil ctx, 'expected llama_init_from_model to return a context pointer'

      prompt = "User: Say hello in one word.\nAssistant:"
      token_capacity = 512
      tokens = FFI::MemoryPointer.new(:int32, token_capacity)
      token_count = Llama.llama_tokenize(model, prompt, prompt.bytesize, tokens, token_capacity, true, true)
      assert_operator token_count, :>, 0, 'expected prompt tokenization to return at least one token'

      batch = Llama.llama_batch_init(token_capacity, 0, 1)
      token_count.times do |i|
        token = tokens.get_int32(i * FFI.type_size(:int32))
        batch[:token].put_int32(i * FFI.type_size(:int32), token)
        batch[:pos].put_int32(i * FFI.type_size(:int32), i)
        batch[:n_seq_id].put_int32(i * FFI.type_size(:int32), 1)
        batch[:seq_id][i].put_int32(0, 0)
        batch[:logits].put_uint8(i, i == token_count - 1 ? 1 : 0)
      end
      batch[:n_tokens] = token_count

      decode_result = Llama.llama_decode(ctx, batch)
      assert_equal 0, decode_result, 'expected llama_decode to succeed'

      chain = Llama.llama_sampler_chain_init(Llama.llama_sampler_chain_default_params)
      Llama.llama_sampler_chain_add(chain, Llama.llama_sampler_init_greedy)

      sampled = Llama.llama_sampler_sample(chain, ctx, -1)
      assert_operator sampled, :>=, 0, 'expected sampled token id'

      piece_buf = FFI::MemoryPointer.new(:char, 64)
      written = Llama.llama_token_to_piece(model, sampled, piece_buf, 64, 0, false)
      assert_operator written, :>, 0, 'expected sampled token to be convertible to text'

      piece = piece_buf.read_string_length([written, 63].min)
      refute_empty piece.strip, 'expected sampled token piece to contain text'
    ensure
      Llama.llama_sampler_free(chain) if chain
      Llama.llama_batch_free(batch) if batch
      Llama.llama_free(ctx) if ctx
      Llama.llama_model_free(model) if model
      Llama.llama_backend_free if defined?(Llama) && Llama.respond_to?(:llama_backend_free)
    end
  end

  private

  def call_backend_init
    return Llama.llama_backend_init unless Llama.method(:llama_backend_init).arity == 1

    Llama.llama_backend_init(false)
  rescue ArgumentError
    Llama.llama_backend_init
  end
end
