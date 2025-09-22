# frozen_string_literal: true

require "active_support/encrypted_file"
require "active_support/core_ext/hash/keys"
require "active_support/core_ext/object/blank"
require "active_support/ordered_options"
require "pathname"
require "erb"
require "yaml"

module Secvault
  class Secrets
    class << self
      def setup(app)
        secrets_path = app.root.join("config/secrets.yml")
        key_path = app.root.join("config/secrets.yml.key")

        if secrets_path.exist?
          # Use a more reliable approach that works in all environments
          app.config.before_configuration do
            current_env = ENV['RAILS_ENV'] || Rails.env || 'development'
            setup_secrets_immediately(app, secrets_path, key_path, current_env)
          end
          
          # Also try during to_prepare as a fallback
          app.config.to_prepare do
            current_env = Rails.env
            unless Rails.application.respond_to?(:secrets) && !Rails.application.secrets.empty?
              setup_secrets_immediately(app, secrets_path, key_path, current_env)
            end
          end
        end
      end

      def setup_secrets_immediately(app, secrets_path, key_path, env)
        # Set up secrets if they exist
        secrets = read_secrets(secrets_path, key_path, env)
        if secrets
          # Rails 8.0+ compatibility: Add secrets accessor that initializes on first access
          unless Rails.application.respond_to?(:secrets)
            Rails.application.define_singleton_method(:secrets) do
              @secrets ||= begin
                current_secrets = ActiveSupport::OrderedOptions.new
                # Re-read secrets to ensure we have the right environment
                env_secrets = Secvault::Secrets.read_secrets(secrets_path, key_path, Rails.env)
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
      # Parses secrets files and merges shared + environment-specific sections
      def parse(paths, env:)
        paths.each_with_object(Hash.new) do |path, all_secrets|
          next unless path.exist?
          
          # Read and process the file content (handle both encrypted and plain)
          source = if encrypted?(path)
            decrypt(path)
          else
            preprocess(path)
          end
          
          # Process ERB and parse YAML
          erb_result = ERB.new(source).result
          secrets = if YAML.respond_to?(:unsafe_load)
            YAML.unsafe_load(erb_result)
          else
            YAML.load(erb_result)
          end
          
          secrets ||= {}
          
          # Merge shared secrets first, then environment-specific
          all_secrets.merge!(secrets["shared"].deep_symbolize_keys) if secrets["shared"]
          all_secrets.merge!(secrets[env].deep_symbolize_keys) if secrets[env]
        end
      end
      
      # Helper method to preprocess plain YAML files (for ERB)
      def preprocess(path)
        path.read
      end

      def read_secrets(secrets_path, key_path, env)
        if secrets_path.exist?
          all_secrets = if key_path.exist? || encrypted?(secrets_path)
            # Handle encrypted secrets.yml
            decrypt_secrets(secrets_path, key_path)
          else
            # Handle plain YAML secrets.yml
            YAML.safe_load(ERB.new(secrets_path.read).result, aliases: true)
          end

          env_secrets = all_secrets[env.to_s]
          return env_secrets.deep_symbolize_keys if env_secrets
        end

        {}
      end

      def encrypted?(path)
        # Simple heuristic to detect if file is encrypted
        content = path.read
        # Encrypted files typically contain non-printable characters
        !content.valid_encoding? || content.bytes.any? { |b| b < 32 && b != 10 && b != 13 }
      rescue
        false
      end

      private

      def decrypt_secrets(secrets_path, key_path)
        encrypted_file = ActiveSupport::EncryptedFile.new(
          content_path: secrets_path,
          key_path: key_path,
          env_key: "RAILS_SECRETS_KEY",
          raise_if_missing_key: true
        )

        content = encrypted_file.read
        YAML.safe_load(ERB.new(content).result, aliases: true) if content.present?
      rescue ActiveSupport::EncryptedFile::MissingKeyError
        raise MissingKeyError,
          "Missing encryption key to decrypt secrets.yml. " \
          "Ask your team for your secrets key and put it in config/secrets.yml.key"
      rescue ActiveSupport::EncryptedFile::InvalidMessage
        raise InvalidKeyError,
          "Invalid encryption key for secrets.yml."
      end

      def decrypt(path)
        key_path = Pathname.new("#{path}.key")
        encrypted_file = ActiveSupport::EncryptedFile.new(
          content_path: path,
          key_path: key_path,
          env_key: "RAILS_SECRETS_KEY",
          raise_if_missing_key: true
        )
        encrypted_file.read
      end
    end
  end
end
