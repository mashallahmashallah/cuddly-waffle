# frozen_string_literal: true

require 'fileutils'
require 'open-uri'
require 'zlib'
require 'rubygems/package'

module LlamaCppFfiGenerator
  class ReleaseFetcher
    REPO = 'https://github.com/ggml-org/llama.cpp'.freeze

    def initialize(tag:, workdir:)
      @tag = tag
      @workdir = workdir
    end

    attr_reader :tag, :workdir

    def fetch
      FileUtils.mkdir_p(workdir)
      archive_path = File.join(workdir, "#{tag}.tar.gz")
      source_dir = File.join(workdir, "llama.cpp-#{tag}")
      return source_dir if File.directory?(source_dir)

      URI.open(archive_url) do |remote|
        File.binwrite(archive_path, remote.read)
      end

      unpack(archive_path, source_dir)
      source_dir
    end

    private

    def archive_url
      "#{REPO}/archive/refs/tags/#{tag}.tar.gz"
    end

    def unpack(archive_path, destination)
      FileUtils.mkdir_p(destination)
      Zlib::GzipReader.open(archive_path) do |gzip|
        Gem::Package::TarReader.new(gzip) do |tar|
          tar.each do |entry|
            next if entry.full_name == '.'

            parts = entry.full_name.split('/')[1..]
            next if parts.nil? || parts.empty?

            target = File.join(destination, *parts)
            if entry.directory?
              FileUtils.mkdir_p(target)
            else
              FileUtils.mkdir_p(File.dirname(target))
              File.binwrite(target, entry.read)
            end
          end
        end
      end
    end
  end
end
