# frozen_string_literal: true

require "active_support/encrypted_file"
require "securerandom"

namespace :secvault do
  desc "Setup secrets.yml file (plain YAML by default)"
  task setup: :environment do
    secrets_path = Rails.root.join("config/secrets.yml")
    key_path = Rails.root.join("config/secrets.yml.key")
    encrypted = ENV["ENCRYPTED"] == "true"

    if secrets_path.exist?
      puts "Secrets file already exists at #{secrets_path}"
    else
      default_content = <<~YAML
        # Be sure to restart your server when you modify this file.
        #
        # Your secret key is used for verifying the integrity of signed cookies.
        # If you change this key, all old signed cookies will become invalid!
        #
        # Make sure the secret is at least 30 characters and all random,
        # no regular words or you'll be exposed to dictionary attacks.
        # You can use `rails secret` to generate a secure secret key.

        development:
          secret_key_base: #{SecureRandom.hex(64)}

        test:
          secret_key_base: #{SecureRandom.hex(64)}

        # Do not keep production secrets in the repository,
        # instead read values from the environment.
        production:
          secret_key_base: <%= ENV["SECRET_KEY_BASE"] %>
      YAML

      if encrypted
        # Create encrypted file
        unless key_path.exist?
          key = ActiveSupport::EncryptedFile.generate_key
          File.write(key_path, key)
          puts "Generated encryption key in #{key_path}"
        end

        encrypted_file = ActiveSupport::EncryptedFile.new(
          content_path: secrets_path,
          key_path: key_path,
          env_key: "RAILS_SECRETS_KEY",
          raise_if_missing_key: true
        )
        encrypted_file.write(default_content)
        puts "Created encrypted secrets.yml file"
        puts "Add #{key_path} to your .gitignore file"
      else
        # Create plain YAML file
        File.write(secrets_path, default_content)
        puts "Created plain secrets.yml file"
        puts "Remember to add #{secrets_path} to your .gitignore if it contains sensitive data"
      end
    end
  end

  desc "Edit secrets.yml file"
  task edit: :environment do
    secrets_path = Rails.root.join("config/secrets.yml")
    key_path = Rails.root.join("config/secrets.yml.key")

    unless secrets_path.exist?
      puts "Secrets file doesn't exist. Run 'rake secvault:setup' first."
      exit 1
    end

    # Check if file is encrypted
    is_encrypted = Secvault::Secrets.encrypted?(secrets_path)

    if is_encrypted && key_path.exist?
      # Handle encrypted file
      encrypted_file = ActiveSupport::EncryptedFile.new(
        content_path: secrets_path,
        key_path: key_path,
        env_key: "RAILS_SECRETS_KEY",
        raise_if_missing_key: true
      )

      encrypted_file.change do |tmp_path|
        system("#{ENV["EDITOR"] || "vi"} #{tmp_path}")
      end

      puts "Updated encrypted #{secrets_path}"
    else
      # Handle plain YAML file
      system("#{ENV["EDITOR"] || "vi"} #{secrets_path}")
      puts "Updated plain #{secrets_path}"
    end
  rescue ActiveSupport::EncryptedFile::MissingKeyError
    puts "Missing encryption key to decrypt secrets.yml."
    puts "Ask your team for your secrets key and put it in #{key_path}"
  rescue ActiveSupport::EncryptedFile::InvalidMessage
    puts "Invalid encryption key for secrets.yml."
  end

  desc "Show secrets.yml content"
  task show: :environment do
    secrets_path = Rails.root.join("config/secrets.yml")
    key_path = Rails.root.join("config/secrets.yml.key")

    unless secrets_path.exist?
      puts "Secrets file doesn't exist. Run 'rake secvault:setup' first."
      exit 1
    end

    # Check if file is encrypted
    is_encrypted = Secvault::Secrets.encrypted?(secrets_path)

    if is_encrypted && key_path.exist?
      # Handle encrypted file
      encrypted_file = ActiveSupport::EncryptedFile.new(
        content_path: secrets_path,
        key_path: key_path,
        env_key: "RAILS_SECRETS_KEY",
        raise_if_missing_key: true
      )
      puts encrypted_file.read
    else
      # Handle plain YAML file
      puts File.read(secrets_path)
    end
  rescue ActiveSupport::EncryptedFile::MissingKeyError
    puts "Missing encryption key to decrypt secrets.yml."
    puts "Ask your team for your secrets key and put it in #{key_path}"
  rescue ActiveSupport::EncryptedFile::InvalidMessage
    puts "Invalid encryption key for secrets.yml."
  end
end
