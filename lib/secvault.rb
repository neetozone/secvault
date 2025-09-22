# frozen_string_literal: true

require "rails"
require "yaml"
require "erb"
require "active_support/encrypted_file"
require "active_support/core_ext/hash/keys"
require "zeitwerk"

require_relative "secvault/version"

loader = Zeitwerk::Loader.for_gem
loader.setup

module Secvault
  class Error < StandardError; end
  class MissingKeyError < Error; end
  class InvalidKeyError < Error; end

  extend self

  def install!
    return if defined?(Rails::Railtie).nil?

    require "secvault/railtie"
  end
end

Secvault.install! if defined?(Rails)
