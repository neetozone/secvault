# frozen_string_literal: true

require "rails/generators/base"
require "active_support/encrypted_file"
require "securerandom"

module Secvault
  module Generators
    class SecretsGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Creates a secrets.yml file for encrypted secrets management"

      class_option :force, type: :boolean, default: false, desc: "Overwrite existing secrets.yml"

      def create_secrets_file
        secrets_path = Rails.root.join("config/secrets.yml")
        key_path = Rails.root.join("config/secrets.yml.key")

        if secrets_path.exist? && !options[:force]
          say "Secrets file already exists at config/secrets.yml", :yellow
          return
        end

        # Generate encryption key
        unless key_path.exist?
          key = ActiveSupport::EncryptedFile.generate_key
          File.write(key_path, key)
          say "Generated encryption key in config/secrets.yml.key", :green
        end

        # Create encrypted secrets file with template
        encrypted_file = ActiveSupport::EncryptedFile.new(
          content_path: secrets_path,
          key_path: key_path,
          env_key: "RAILS_SECRETS_KEY",
          raise_if_missing_key: true
        )

        # Write default content
        default_content = generate_default_secrets
        encrypted_file.write(default_content)

        say "Created encrypted secrets.yml file", :green
        say "Add config/secrets.yml.key to your .gitignore file", :yellow
      end

      def add_to_gitignore
        gitignore_path = Rails.root.join(".gitignore")
        key_entry = "/config/secrets.yml.key"

        if gitignore_path.exist?
          gitignore_content = File.read(gitignore_path)
          unless gitignore_content.include?(key_entry)
            File.open(gitignore_path, "a") do |f|
              f.puts "\n# Ignore encrypted secrets key"
              f.puts key_entry
            end
            say "Added secrets key to .gitignore", :green
          end
        end
      end

      private

      def generate_default_secrets
        <<~YAML
          # Be sure to restart your server when you modify this file.
          
          # Your secret key is used for verifying the integrity of signed cookies.
          # If you change this key, all old signed cookies will become invalid!
          
          # Make sure the secret is at least 30 characters and all random,
          # no regular words or you'll be exposed to dictionary attacks.
          # You can use `rails secret` to generate a secure secret key.
          
          # Make sure the secrets in this file are kept private
          # if you're sharing your code publicly.
          
          development:
            secret_key_base: #{SecureRandom.hex(64)}
          
          test:
            secret_key_base: #{SecureRandom.hex(64)}
          
          # Do not keep production secrets in the repository,
          # instead read values from the environment.
          production:
            secret_key_base: <%= ENV["SECRET_KEY_BASE"] %>
        YAML
      end
    end
  end
end
