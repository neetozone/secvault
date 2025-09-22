# frozen_string_literal: true

require "rails"
require "yaml"
require "erb"
require "active_support/core_ext/hash/keys"
require "zeitwerk"

require_relative "secvault/version"

loader = Zeitwerk::Loader.for_gem
loader.setup

# Secvault - Simple secrets management for Rails
# 
# Secvault restores the classic Rails secrets.yml functionality that was removed 
# in Rails 7.2, using simple, plain YAML files for environment-specific secrets 
# management.
#
# ## Rails Version Support:
# - Rails 7.1: Requires manual setup (see Rails 7.1 integration guide)
# - Rails 7.2+: Automatic setup, drop-in replacement for removed functionality
# - Rails 8.0+: Full compatibility
#
# ## Rails 7.1 Integration:
# For Rails 7.1 apps, add this initializer to override native Rails::Secrets:
#
#   # config/initializers/secvault.rb
#   module Rails
#     remove_const(:Secrets) if defined?(Secrets)
#     Secrets = Secvault::RailsSecrets
#   end
#
#   Rails.application.config.after_initialize do
#     secrets_path = Rails.root.join("config/secrets.yml")
#     if secrets_path.exist?
#       loaded_secrets = Rails::Secrets.parse([secrets_path], env: Rails.env)
#       secrets_object = ActiveSupport::OrderedOptions.new
#       secrets_object.merge!(loaded_secrets)
#       Rails.application.define_singleton_method(:secrets) { secrets_object }
#     end
#   end
#
# ## Usage:
#   Rails.application.secrets.api_key
#   Rails.application.secrets.oauth_settings[:google_client_id]
#   Rails::Secrets.parse_default(env: 'development')
#
# ## Getting Started:
#   1. Create config/secrets.yml with your secrets
#   2. Use Rails.application.secrets.your_secret in your app
#   3. For production, use environment variables with ERB syntax
#
# @see https://github.com/unnitallman/secvault
module Secvault
  class Error < StandardError; end

  extend self

  def install!
    return if defined?(Rails::Railtie).nil?

    require "secvault/railtie"
    require "secvault/rails_secrets"
  end
  
  # Helper method to set up Secvault for Rails 7.1 applications
  # This provides an easy way to integrate Secvault into Rails 7.1 apps
  # that still have native Rails::Secrets functionality.
  #
  # Usage in an initializer:
  #   Secvault.setup_rails_71_integration!
  #
  # This will:
  # 1. Override native Rails::Secrets with Secvault implementation
  # 2. Replace Rails.application.secrets with Secvault-powered functionality
  # 3. Load secrets from config/secrets.yml automatically
  def setup_rails_71_integration!
    # Override native Rails::Secrets
    if defined?(Rails::Secrets)
      Rails.send(:remove_const, :Secrets)
    end
    Rails.const_set(:Secrets, Secvault::RailsSecrets)
    
    # Set up Rails.application.secrets replacement
    Rails.application.config.after_initialize do
      secrets_path = Rails.root.join("config/secrets.yml")
      
      if secrets_path.exist?
        # Load secrets using Secvault
        loaded_secrets = Rails::Secrets.parse([secrets_path], env: Rails.env)
        
        # Create ActiveSupport::OrderedOptions object for compatibility
        secrets_object = ActiveSupport::OrderedOptions.new
        secrets_object.merge!(loaded_secrets)
        
        # Replace Rails.application.secrets
        Rails.application.define_singleton_method(:secrets) do
          secrets_object
        end
        
        # Log integration success (except in production)
        unless Rails.env.production?
          Rails.logger&.info "[Secvault] Rails 7.1 integration complete. Loaded #{loaded_secrets.keys.size} secret keys."
        end
      else
        Rails.logger&.warn "[Secvault] No secrets.yml file found at #{secrets_path}"
      end
    end
  end
end

Secvault.install! if defined?(Rails)
