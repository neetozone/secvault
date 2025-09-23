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
#   Rails::Secrets.load(env: 'development')  # Load default config/secrets.yml
#   Rails::Secrets.parse(['custom.yml'], env: Rails.env)  # Parse custom files
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

  # Internal storage for loaded secrets
  @@loaded_secrets = nil

  # Access to loaded secrets without Rails integration
  def secrets
    @@loaded_secrets || ActiveSupport::OrderedOptions.new
  end

  # Check if Secvault is currently active (started)
  def active?
    @@loaded_secrets != nil
  end

  # Check if Secvault is integrated with Rails.application.secrets
  def rails_integrated?
    defined?(Rails) && Rails::Secrets == Secvault::RailsSecrets
  end

  def install!
    return if defined?(Rails::Railtie).nil?

    require "secvault/railtie"
    require "secvault/rails_secrets"
  end

  # Helper method to set up Secvault for older Rails versions
  # This provides an easy way to integrate Secvault into older Rails apps
  # that still have native Rails::Secrets functionality (like Rails 7.1).
  #
  # Usage in an initializer:
  #   Secvault.setup_backward_compatibility_with_older_rails!
  #
  # This will:
  # 1. Override native Rails::Secrets with Secvault implementation
  # 2. Replace Rails.application.secrets with Secvault-powered functionality
  # 3. Load secrets from config/secrets.yml automatically
  def setup_backward_compatibility_with_older_rails!
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

  # Set up multi-file secrets loading with a clean API
  # Just pass an array of file paths and Secvault handles the rest
  #
  # Usage in an initializer:
  #   Secvault.setup_multi_file!([
  #     'config/secrets.yml',
  #     'config/secrets.oauth.yml',
  #     'config/secrets.local.yml'
  #   ])
  #
  # Options:
  #   - files: Array of file paths (String or Pathname)
  #   - reload_method: Add a reload helper method (default: true in development)
  #   - logger: Enable/disable logging (default: true except in production)
  def setup_multi_file!(files, reload_method: Rails.env.development?, logger: !Rails.env.production?)
    # Ensure Secvault integration is active
    setup_backward_compatibility_with_older_rails! unless active?

    # Convert strings to Pathname objects and resolve relative to Rails.root
    file_paths = Array(files).map do |file|
      file.is_a?(Pathname) ? file : Rails.root.join(file)
    end

    # Set up the multi-file loading
    Rails.application.config.after_initialize do
      load_multi_file_secrets!(file_paths, logger: logger)
    end

    # Add reload helper in development
    if reload_method
      add_reload_helper!(file_paths)
    end
  end

  # Load secrets into Secvault.secrets only (no Rails integration)
  def load_secrets_only!(files, logger: !Rails.env.production?)
    # Convert strings to Pathname objects and resolve relative to Rails.root
    file_paths = Array(files).map do |file|
      file.is_a?(Pathname) ? file : Rails.root.join(file)
    end

    existing_files = file_paths.select(&:exist?)

    if existing_files.any?
      # Load and merge all secrets files using Secvault's parser directly
      merged_secrets = Secvault::Secrets.parse(existing_files, env: Rails.env)

      # Store in Secvault.secrets (ActiveSupport::OrderedOptions for compatibility)
      @@loaded_secrets = ActiveSupport::OrderedOptions.new
      @@loaded_secrets.merge!(merged_secrets)

      # Log successful loading
      if logger
        file_names = existing_files.map(&:basename)
        Rails.logger&.info "[Secvault] Loaded #{existing_files.size} files: #{file_names.join(", ")}"
        Rails.logger&.info "[Secvault] Parsed #{merged_secrets.keys.size} secret keys for #{Rails.env}"
      end

      true
    else
      Rails.logger&.warn "[Secvault] No secrets files found" if logger
      @@loaded_secrets = ActiveSupport::OrderedOptions.new
      false
    end
  end

  # Load secrets from multiple files and merge them (with Rails integration)
  def load_multi_file_secrets!(file_paths, logger: !Rails.env.production?)
    existing_files = file_paths.select(&:exist?)

    if existing_files.any?
      # Load and merge all secrets files
      merged_secrets = Rails::Secrets.parse(existing_files, env: Rails.env)

      # Create ActiveSupport::OrderedOptions object for Rails compatibility
      secrets_object = ActiveSupport::OrderedOptions.new
      secrets_object.merge!(merged_secrets)

      # Replace Rails.application.secrets
      Rails.application.define_singleton_method(:secrets) { secrets_object }

      # Log successful loading
      if logger
        file_names = existing_files.map(&:basename)
        Rails.logger&.info "[Secvault Multi-File] Loaded #{existing_files.size} files: #{file_names.join(", ")}"
        Rails.logger&.info "[Secvault Multi-File] Merged #{merged_secrets.keys.size} secret keys for #{Rails.env}"
      end

      merged_secrets
    else
      Rails.logger&.warn "[Secvault Multi-File] No secrets files found" if logger
      {}
    end
  end

  # Add reload helper method for development
  def add_reload_helper!(file_paths)
    # Define reload method on Rails.application
    Rails.application.define_singleton_method(:reload_secrets!) do
      Secvault.load_multi_file_secrets!(file_paths, logger: true)
      puts "🔄 Reloaded secrets from #{file_paths.size} files"
      true
    end

    # Also make it available as a top-level method
    Object.define_method(:reload_secrets!) do
      Rails.application.reload_secrets!
    end
  end

  # Start Secvault and load secrets (without Rails integration)
  #
  # Usage:
  #   Secvault.start!                                    # Uses config/secrets.yml only
  #   Secvault.start!(files: [])                        # Same as above
  #   Secvault.start!(files: ['path/to/secrets.yml'])   # Custom single file
  #   Secvault.start!(files: ['gem.yml', 'app.yml'])    # Multiple files
  #
  # Access loaded secrets via: Secvault.secrets.your_key
  # To integrate with Rails.application.secrets, call: Secvault.integrate_with_rails!
  #
  # Options:
  #   - files: Array of file paths (String or Pathname). Defaults to ['config/secrets.yml']
  #   - logger: Enable logging (default: true except production)
  def start!(files: [], logger: !Rails.env.production?)
    # Default to host app's config/secrets.yml if no files specified
    files_to_load = files.empty? ? ["config/secrets.yml"] : files

    # Load secrets into Secvault.secrets (completely independent of Rails)
    load_secrets_only!(files_to_load, logger: logger)

    true
  rescue => e
    Rails.logger&.error "[Secvault] Failed to start: #{e.message}" if defined?(Rails)
    false
  end

  # Integrate loaded secrets with Rails.application.secrets
  def integrate_with_rails!
    return false unless @@loaded_secrets

    begin
      # Set up Rails::Secrets to use Secvault's parser (only when integrating)
      unless rails_integrated?
        if defined?(Rails::Secrets)
          Rails.send(:remove_const, :Secrets)
        end
        Rails.const_set(:Secrets, Secvault::RailsSecrets)
      end

      # Replace Rails.application.secrets with Secvault's loaded secrets
      Rails.application.define_singleton_method(:secrets) do
        Secvault.secrets
      end

      Rails.logger&.info "[Secvault] Integrated with Rails.application.secrets" unless Rails.env.production?
      true
    rescue => e
      Rails.logger&.error "[Secvault] Failed to integrate with Rails: #{e.message}" if defined?(Rails)
      false
    end
  end

  # Backward compatibility aliases
  alias_method :setup_rails_71_integration!, :setup_backward_compatibility_with_older_rails!
  alias_method :setup_multi_files!, :setup_multi_file!  # Alternative name
end

Secvault.install! if defined?(Rails)
