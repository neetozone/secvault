# frozen_string_literal: true

require "active_support/core_ext/hash/keys"
require "active_support/core_ext/hash/deep_merge"
require "active_support/ordered_options"
require "pathname"
require "erb"
require "yaml"

module Secvault
  class Secrets
    class << self
      def setup(app)
        # Only auto-setup for Rails 7.2+ where secrets functionality was removed
        return unless rails_7_2_or_later?
        
        secrets_path = app.root.join("config/secrets.yml")

        if secrets_path.exist?
          # Use a more reliable approach that works in all environments
          app.config.before_configuration do
            current_env = ENV['RAILS_ENV'] || Rails.env || 'development'
            setup_secrets_immediately(app, secrets_path, current_env)
          end
          
          # Also try during to_prepare as a fallback
          app.config.to_prepare do
            current_env = Rails.env
            unless Rails.application.respond_to?(:secrets) && !Rails.application.secrets.empty?
              setup_secrets_immediately(app, secrets_path, current_env)
            end
          end
        end
      end
      
      # Manual setup method for Rails 7.1 (opt-in)
      def setup_for_rails_71!(app)
        secrets_path = app.root.join("config/secrets.yml")

        if secrets_path.exist?
          app.config.before_configuration do
            current_env = ENV['RAILS_ENV'] || Rails.env || 'development'
            setup_secrets_immediately(app, secrets_path, current_env)
          end
        end
      end

      def setup_secrets_immediately(app, secrets_path, env)
        # Set up secrets if they exist
        secrets = read_secrets(secrets_path, env)
        if secrets
          # Rails 8.0+ compatibility: Add secrets accessor that initializes on first access
          unless Rails.application.respond_to?(:secrets)
            Rails.application.define_singleton_method(:secrets) do
              @secrets ||= begin
                current_secrets = ActiveSupport::OrderedOptions.new
                # Re-read secrets to ensure we have the right environment
                env_secrets = Secvault::Secrets.read_secrets(secrets_path, Rails.env)
                current_secrets.merge!(env_secrets) if env_secrets
                current_secrets
              end
            end
          end
          
          # If secrets accessor already exists, merge the secrets
          if Rails.application.respond_to?(:secrets) && Rails.application.secrets.respond_to?(:merge!)
            Rails.application.secrets.merge!(secrets)
          end
        end
      end

      # Classic Rails::Secrets.parse implementation
      # Parses plain YAML secrets files and merges shared + environment-specific sections
      def parse(paths, env:)
        paths.each_with_object(Hash.new) do |path, all_secrets|
          # Handle string paths by converting to Pathname
          path = Pathname.new(path) unless path.respond_to?(:exist?)
          next unless path.exist?
          
          # Read and process the plain YAML file content
          source = path.read
          
          # Process ERB and parse YAML
          erb_result = ERB.new(source).result
          secrets = if YAML.respond_to?(:unsafe_load)
            YAML.unsafe_load(erb_result)
          else
            YAML.load(erb_result)
          end
          
          secrets ||= {}
          
          # Merge shared secrets first, then environment-specific (using deep merge)
          all_secrets.deep_merge!(secrets["shared"].deep_symbolize_keys) if secrets["shared"]
          all_secrets.deep_merge!(secrets[env].deep_symbolize_keys) if secrets[env]
        end
      end

      def read_secrets(secrets_path, env)
        if secrets_path.exist?
          # Handle plain YAML secrets.yml only
          all_secrets = YAML.safe_load(ERB.new(secrets_path.read).result, aliases: true)
          
          env_secrets = all_secrets[env.to_s]
          return env_secrets.deep_symbolize_keys if env_secrets
        end

        {}
      end

      private
      
      def rails_7_2_or_later?
        rails_version = Rails.version
        major, minor = rails_version.split('.').map(&:to_i)
        major > 7 || (major == 7 && minor >= 2)
      end
    end
  end
end
