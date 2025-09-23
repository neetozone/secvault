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
# Secvault restores the classic Rails secrets.yml functionality using simple,
# plain YAML files for environment-specific secrets management. Works consistently
# across all Rails versions.
#
# ## Rails Version Support:
# - Rails 7.1+: Full compatibility with automatic setup
# - Rails 7.2+: Drop-in replacement for removed functionality
# - Rails 8.0+: Full compatibility
#
# ## Quick Start:
# Add this to an initializer:
#
#   # config/initializers/secvault.rb
#   Secvault.start!
#
# ## Usage:
#   Rails.application.secrets.api_key
#   Rails.application.secrets.oauth_settings[:google_client_id]
#   Secvault.secrets.your_key  # Direct access
#   Rails::Secrets.load(env: 'development')  # Load default config/secrets.yml
#   Rails::Secrets.parse(['custom.yml'], env: Rails.env)  # Parse custom files
#
# ## Getting Started:
#   1. Create config/secrets.yml with your secrets
#   2. Call Secvault.start! in an initializer
#   3. Use Rails.application.secrets.your_secret in your app
#   4. For production, use environment variables with ERB syntax
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

  # Early setup method for use in config/application.rb before other configuration
  # This ensures Rails.application has secrets available during application class definition
  def setup_early_application_secrets!(files: nil, application_class: nil)
    return false unless defined?(Rails)
    
    # Default files if not provided
    files ||= begin
      default_files = ["config/secrets.yml"]
      
      # Add neeto-commons-backend file if available
      if defined?(NeetoCommonsBackend) && NeetoCommonsBackend.respond_to?(:shared_secrets_file)
        default_files.unshift(NeetoCommonsBackend.shared_secrets_file)
      end
      
      default_files
    end
    
    # Create a temporary Rails.application if it doesn't exist
    unless Rails.respond_to?(:application) && Rails.application
      # Create a temporary application-like object with secrets
      temp_app = Object.new
      
      # Add lazy secrets loading
      temp_app.define_singleton_method(:secrets) do
        @secrets ||= begin
          # Convert to full paths and filter existing files
          file_paths = files.map do |file|
            file.is_a?(Pathname) ? file : Rails.root.join(file)
          end.select(&:exist?)
          
          if file_paths.any?
            # Load secrets using Secvault
            all_secrets = Secvault::Secrets.parse(file_paths, env: Rails.env)
            current_secrets = ActiveSupport::OrderedOptions.new
            current_secrets.merge!(all_secrets)
            current_secrets
          else
            # Return empty secrets if no files found but include encryption structure
            secrets = ActiveSupport::OrderedOptions.new
            secrets.encryption = ActiveSupport::OrderedOptions.new
            secrets.encryption.primary_key = nil
            secrets.encryption.deterministic_key = nil
            secrets.encryption.key_derivation_salt = nil
            secrets
          end
        end
      end
      
      # Set up Rails.application to point to this temporary object
      Rails.define_singleton_method(:application) { temp_app }
    end
    
    true
  rescue => e
    warn "[Secvault] Early application secrets setup failed: #{e.message}"
    false
  end
  
  # Alias for backward compatibility
  alias_method :setup_early_secrets!, :setup_early_application_secrets!

  def install!
    return if defined?(Rails::Railtie).nil?

    require "secvault/railtie"
    require "secvault/rails_secrets"
  end

  # Start Secvault with simplified, unified API
  # This is the main entry point for all Secvault functionality
  #
  # Usage examples:
  #   Secvault.start!                                    # Simple: config/secrets.yml + Rails integration
  #   Secvault.start!(files: ['custom.yml'])            # Custom single file
  #   Secvault.start!(files: ['base.yml', 'local.yml']) # Multiple files
  #   Secvault.start!(integrate_with_rails: false)      # Load only, no Rails integration
  #   Secvault.start!(hot_reload: true)                 # Enable hot reload in development
  #
  # Access secrets:
  #   Rails.application.secrets.your_key  # When integrate_rails: true (default)
  #   Secvault.secrets.your_key           # Direct access (always available)
  #
  # Options:
  #   - files: Array of file paths (String or Pathname). Defaults to ['config/secrets.yml']
  #   - integrate_with_rails: Integrate with Rails.application.secrets (default: false)
  #   - set_secret_key_base: Set Rails.application.config.secret_key_base from secrets (default: true)
  #   - hot_reload: Add reload_secrets! methods for development (default: true in development)
  #   - logger: Enable logging (default: true except production)
  def start!(files: [], integrate_with_rails: false, set_secret_key_base: true, 
             hot_reload: (defined?(Rails) && Rails.env.respond_to?(:development?) ? Rails.env.development? : false), 
             logger: (defined?(Rails) && Rails.env.respond_to?(:production?) ? !Rails.env.production? : true))
    
    # Default to config/secrets.yml if no files specified
    files_to_load = files.empty? ? ["config/secrets.yml"] : Array(files)
    
    # Convert to Pathname objects and resolve relative to Rails.root
    file_paths = files_to_load.map do |file|
      file.is_a?(Pathname) ? file : Rails.root.join(file)
    end
    
    # Load secrets into Secvault.secrets
    load_secrets!(file_paths, logger: logger)
    
    # Integrate with Rails if requested
    if integrate_with_rails
      setup_rails_integration!(file_paths, set_secret_key_base: set_secret_key_base, logger: logger)
    end
    
    # Add hot reload functionality if requested
    if hot_reload
      add_hot_reload!(file_paths)
    end
    
    true
  rescue => e
    Rails.logger&.error "[Secvault] Failed to start: #{e.message}" if defined?(Rails) && logger
    false
  end

  private

  # Load secrets into Secvault.secrets (internal storage)
  def load_secrets!(file_paths, logger: (defined?(Rails) && Rails.env.respond_to?(:production?) ? !Rails.env.production? : true))
    existing_files = file_paths.select(&:exist?)
    
    if existing_files.any?
      # Load and merge all secrets files
      merged_secrets = Secvault::Secrets.parse(existing_files, env: Rails.env)
      
      # Store in internal storage with ActiveSupport::OrderedOptions for compatibility
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
  
  # Set up Rails integration
  def setup_rails_integration!(file_paths, set_secret_key_base: true, logger: (defined?(Rails) && Rails.env.respond_to?(:production?) ? !Rails.env.production? : true))
    # Override native Rails::Secrets with Secvault implementation
    Rails.send(:remove_const, :Secrets) if defined?(Rails::Secrets)
    Rails.const_set(:Secrets, Secvault::RailsSecrets)
    
    # Set up Rails.application.secrets replacement in after_initialize
    Rails.application.config.after_initialize do
      if @@loaded_secrets && !@@loaded_secrets.empty?
        # Replace Rails.application.secrets with our loaded secrets
        Rails.application.define_singleton_method(:secrets) do
          @@loaded_secrets
        end
        
        # Set secret_key_base in Rails config to avoid accessing it from secrets
        if set_secret_key_base && @@loaded_secrets.key?(:secret_key_base)
          Rails.application.config.secret_key_base = @@loaded_secrets[:secret_key_base]
          Rails.logger&.info "[Secvault] Set Rails.application.config.secret_key_base from secrets" if logger
        end
        
        # Log integration success (except in production)
        if logger
          Rails.logger&.info "[Secvault] Rails integration complete. #{@@loaded_secrets.keys.size} secret keys available."
        end
      else
        Rails.logger&.warn "[Secvault] No secrets loaded for Rails integration" if logger
      end
    end
  end
  
  # Add hot reload functionality for development
  def add_hot_reload!(file_paths)
    # Define reload method on Rails.application
    Rails.application.define_singleton_method(:reload_secrets!) do
      # Reload secrets
      Secvault.send(:load_secrets!, file_paths, logger: true)
      
      # Re-apply Rails integration if needed
      if Secvault.rails_integrated? && @@loaded_secrets
        Rails.application.define_singleton_method(:secrets) do
          @@loaded_secrets
        end
      end
      
      puts "🔄 Hot reloaded secrets from #{file_paths.size} files"
      true
    end
    
    # Also make it available as a top-level method
    Object.define_method(:reload_secrets!) do
      Rails.application.reload_secrets!
    end
    
    Rails.logger&.info "[Secvault] Hot reload enabled. Use reload_secrets! to refresh secrets." unless (defined?(Rails) && Rails.env.respond_to?(:production?) && Rails.env.production?)
  end
  
  public

end

# Auto-install and setup when Rails is available
if defined?(Rails)
  Secvault.install!
  
  # Immediate setup for early access during application loading
  begin
    # Try to detect and load secrets immediately if Rails.root is available
    if Rails.respond_to?(:root) && Rails.root
      # Look for default secrets or configuration
      default_secrets_file = Rails.root.join("config/secrets.yml")
      commons_secrets_file = nil
      
      # Check for neeto-commons-backend integration
      if defined?(NeetoCommonsBackend) && NeetoCommonsBackend.respond_to?(:shared_secrets_file)
        commons_secrets_file = NeetoCommonsBackend.shared_secrets_file
      end
      
      files_to_load = [commons_secrets_file, default_secrets_file].compact.select(&:exist?)
      
      if files_to_load.any? && Rails.respond_to?(:env)
        # Load secrets immediately
        all_secrets = Secvault::Secrets.parse(files_to_load, env: Rails.env)
        
        # Set up Rails.application.secrets if Rails.application exists
        if Rails.respond_to?(:application) && Rails.application
          Rails.application.define_singleton_method(:secrets) do
            @secrets ||= begin
              current_secrets = ActiveSupport::OrderedOptions.new
              current_secrets.merge!(all_secrets)
              current_secrets
            end
          end
        else
          # Create a minimal Rails.application for early access
          temp_app = Object.new
          temp_app.define_singleton_method(:secrets) do
            @secrets ||= begin
              current_secrets = ActiveSupport::OrderedOptions.new
              current_secrets.merge!(all_secrets)
              current_secrets
            end
          end
          
          Rails.define_singleton_method(:application) { temp_app } unless Rails.respond_to?(:application)
        end
      end
    end
  rescue => e
    # Silent fail - normal initialization will handle it
    warn "[Secvault] Early auto-load failed: #{e.message}" unless Rails.env&.production?
  end
end
