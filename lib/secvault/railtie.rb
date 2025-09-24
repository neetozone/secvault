# frozen_string_literal: true

require "rails/railtie"

# Extremely early hook to set up Rails.application.secrets before Application class is defined
if defined?(Rails)
  # Set up a robust Rails.application with secrets support
  unless Rails.respond_to?(:application) && Rails.application.respond_to?(:secrets)
    # Create a minimal application-like object
    temp_app = Object.new

    # Add secrets method with default empty secrets that include needed encryption keys
    temp_app.define_singleton_method(:secrets) do
      @secrets ||= begin
        secrets = ActiveSupport::OrderedOptions.new

        # Add empty encryption section to prevent NoMethodError
        secrets.encryption = {
          primary_key: nil,
          deterministic_key: nil,
          key_derivation_salt: nil
        }

        secrets
      end
    end

    # Set up Rails.application if it doesn't exist
    Rails.define_singleton_method(:application) { temp_app } unless Rails.respond_to?(:application)
  end
end

module Secvault
  class Railtie < Rails::Railtie
    railtie_name :secvault

    # Hook to set up early secrets access before application configuration
    config.before_configuration do |app|
      Secvault::EarlyLoader.setup_early_secrets(app)
    end

    initializer "secvault.initialize", before: :load_environment_hook do |app|
      Secvault::Secrets.setup(app)
    end
  end

  # Early loader class to handle secrets before application configuration
  class EarlyLoader
    class << self
      def setup_early_secrets(app)
        puts "[Secvault Debug] setup_early_secrets called" unless Rails.env.production?

        if Rails.application.respond_to?(:secrets) && !Rails.application.secrets.empty?
          puts "[Secvault Debug] Secrets already exist, skipping early load" unless Rails.env.production?
          return
        end

        # Look for Secvault configuration in the app
        secrets_config = find_secvault_config(app)
        puts "[Secvault Debug] Found config: #{secrets_config&.keys}" unless Rails.env.production?
        return unless secrets_config

        begin
          # Load secrets using the configuration found
          all_secrets = Secvault::Secrets.parse(secrets_config[:files], env: Rails.env)
          puts "[Secvault Debug] Loaded secrets keys: #{all_secrets.keys}" unless Rails.env.production?

          # Set up Rails.application.secrets immediately
          Rails.application.define_singleton_method(:secrets) do
            @secrets ||= begin
              current_secrets = ActiveSupport::OrderedOptions.new
              current_secrets.merge!(all_secrets)
              puts "[Secvault Debug] Returning secrets with encryption: #{current_secrets.encryption}" unless Rails.env.production?
              current_secrets
            end
          end

          # Test the secrets immediately
          test_encryption = Rails.application.secrets.encryption
          puts "[Secvault Debug] Test access - encryption: #{test_encryption.class} - #{test_encryption}" unless Rails.env.production?

          Rails.logger&.info "[Secvault] Early secrets loaded from #{secrets_config[:files].size} files" unless Rails.env.production?
        rescue => e
          Rails.logger&.warn "[Secvault] Failed to load early secrets: #{e.message}"
        end
      end

      private

      def find_secvault_config(app)
        # Look for Secvault configuration in various locations
        config_locations = [
          app.root.join("config/initializers/secvault.rb"),
          app.root.join("config/secvault.rb")
        ]

        config_locations.each do |config_file|
          next unless config_file.exist?

          config = parse_secvault_config(config_file)
          return config if config
        end

        # Fallback to default configuration
        default_files = [app.root.join("config/secrets.yml")]

        # Check if neeto-commons-backend is available for default config
        if defined?(NeetoCommonsBackend) && NeetoCommonsBackend.respond_to?(:shared_secrets_file)
          default_files.unshift(NeetoCommonsBackend.shared_secrets_file)
        end

        # Only return default if at least one file exists
        existing_files = default_files.select(&:exist?)
        return {files: existing_files} if existing_files.any?

        nil
      end

      def parse_secvault_config(config_file)
        # Read the configuration file and extract Secvault.start! parameters
        content = config_file.read

        # Look for Secvault.start! calls
        if /Secvault\.start!\s*\(/m.match?(content)
          # Try to extract the files parameter using a simple regex
          files_match = content.match(/files:\s*\[(.*?)\]/m)
          if files_match
            # Parse the files array (basic string parsing)
            files_content = files_match[1]
            files = []

            # Handle various file specification patterns
            files_content.scan(/["'](.*?)["']|([A-Za-z_][\w.]*\([^)]*\))/) do |quoted, method_call|
              if quoted
                files << Rails.root.join(quoted.strip)
              elsif method_call
                # Handle method calls like NeetoCommonsBackend.shared_secrets_file
                if method_call.include?("NeetoCommonsBackend.shared_secrets_file") && defined?(NeetoCommonsBackend)
                  files << NeetoCommonsBackend.shared_secrets_file
                end
              end
            end

            return {files: files.compact} if files.any?
          end
        end

        nil
      rescue => e
        Rails.logger&.warn "[Secvault] Failed to parse config file #{config_file}: #{e.message}"
        nil
      end
    end
  end
end
