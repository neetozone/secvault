# frozen_string_literal: true

require "active_support/core_ext/hash/keys"
require "active_support/core_ext/hash/deep_merge"
require "active_support/ordered_options"
require "pathname"
require "erb"
require "yaml"
require "bigdecimal"
require "date"

module Secvault
  class Secrets
    # Define permitted classes for YAML.safe_load - commonly used in Rails secrets
    PERMITTED_YAML_CLASSES = [
      Symbol,
      Date,
      Time,
      DateTime,
      BigDecimal,
      Range,
      Regexp
    ].tap do |classes|
      # Add ActiveSupport classes if available
      begin
        require "active_support/time_with_zone"
        classes << ActiveSupport::TimeWithZone
      rescue LoadError
        # ActiveSupport not available, skip
      end

      begin
        require "active_support/duration"
        classes << ActiveSupport::Duration
      rescue LoadError
        # ActiveSupport not available, skip
      end
    end.freeze

    class << self
      def setup(app)
        # Auto-setup for all Rails versions with consistent behavior
        secrets_path = app.root.join("config/secrets.yml")

        return unless secrets_path.exist?

        # Use a reliable approach that works in all environments
        app.config.before_configuration do
          current_env = ENV["RAILS_ENV"] || Rails.env || "development"
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

      def setup_secrets_immediately(_app, secrets_path, env)
        # Set up secrets if they exist
        secrets = read_secrets(secrets_path, env)
        return unless secrets

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
        return unless Rails.application.respond_to?(:secrets) && Rails.application.secrets.respond_to?(:merge!)

        Rails.application.secrets.merge!(secrets)
      end

      # Classic Rails::Secrets.parse implementation
      # Parses plain YAML secrets files for specific environment
      def parse(paths, env:)
        paths.each_with_object({}) do |path, all_secrets|
          # Handle string paths by converting to Pathname
          path = Pathname.new(path) unless path.respond_to?(:exist?)
          next unless path.exist?

          # Read and process the plain YAML file content
          source = path.read

          # Process ERB and parse YAML - using same method as Rails
          erb_result = ERB.new(source).result
          secrets = YAML.respond_to?(:unsafe_load) ? YAML.unsafe_load(erb_result) : YAML.safe_load(erb_result, aliases: true, permitted_classes: PERMITTED_YAML_CLASSES)

          secrets ||= {}

          # Only load environment-specific section (YAML anchors handle sharing)
          all_secrets.deep_merge!(secrets[env].deep_symbolize_keys) if secrets[env]
        end
      end

      def read_secrets(secrets_path, env)
        if secrets_path.exist?
          # Handle plain YAML secrets.yml only - using same method as Rails
          erb_result = ERB.new(secrets_path.read).result
          all_secrets = YAML.respond_to?(:unsafe_load) ? YAML.unsafe_load(erb_result) : YAML.safe_load(erb_result, aliases: true, permitted_classes: PERMITTED_YAML_CLASSES)

          env_secrets = all_secrets[env.to_s]
          return env_secrets.deep_symbolize_keys if env_secrets
        end

        {}
      end
    end
  end
end
