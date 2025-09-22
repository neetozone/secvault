# frozen_string_literal: true

require "active_support/encrypted_file"
require "active_support/core_ext/hash/keys"
require "active_support/core_ext/object/blank"
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
          app.config.before_configuration do
            # Set up secrets if they exist
            secrets = read_secrets(secrets_path, key_path, Rails.env)
            Rails.application.secrets.merge!(secrets) if secrets
          end
        end
      end

      def parse(paths, env:)
        configs = paths.collect do |path|
          if path.exist?
            content = encrypted?(path) ? decrypt(path) : path.read
            YAML.safe_load(ERB.new(content).result, aliases: true) || {}
          else
            {}
          end
        end

        configs.reverse.reduce do |config, overrides|
          config.deep_merge(overrides)
        end[env] || {}
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
