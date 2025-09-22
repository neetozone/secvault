# frozen_string_literal: true

require "active_support/encrypted_file"
require "securerandom"

namespace :secvault do
  desc "Setup encrypted secrets.yml file"
  task setup: :environment do
    secrets_path = Rails.root.join("config/secrets.yml")
    key_path = Rails.root.join("config/secrets.yml.key")

    if secrets_path.exist?
      puts "Secrets file already exists at #{secrets_path}"
    else
      # Generate key if it doesn't exist
      unless key_path.exist?
        key = ActiveSupport::EncryptedFile.generate_key
        File.write(key_path, key)
        puts "Generated encryption key in #{key_path}"
      end

      # Create encrypted file with default content
      encrypted_file = ActiveSupport::EncryptedFile.new(
        content_path: secrets_path,
        key_path: key_path,
        env_key: "RAILS_SECRETS_KEY",
        raise_if_missing_key: true
      )

      default_content = <<~YAML
        # Be sure to restart your server when you modify this file.

        development:
          secret_key_base: #{SecureRandom.hex(64)}

        test:
          secret_key_base: #{SecureRandom.hex(64)}

        production:
          secret_key_base: <%= ENV["SECRET_KEY_BASE"] %>
      YAML

      encrypted_file.write(default_content)
      puts "Created encrypted secrets.yml file"
      puts "Add #{key_path} to your .gitignore file"
    end
  end

  desc "Edit encrypted secrets.yml file"
  task edit: :environment do
    secrets_path = Rails.root.join("config/secrets.yml")
    key_path = Rails.root.join("config/secrets.yml.key")

    unless secrets_path.exist?
      puts "Secrets file doesn't exist. Run 'rake secvault:setup' first."
      exit 1
    end

    encrypted_file = ActiveSupport::EncryptedFile.new(
      content_path: secrets_path,
      key_path: key_path,
      env_key: "RAILS_SECRETS_KEY",
      raise_if_missing_key: true
    )

    encrypted_file.change do |tmp_path|
      system("#{ENV["EDITOR"] || "vi"} #{tmp_path}")
    end

    puts "Updated #{secrets_path}"
  rescue ActiveSupport::EncryptedFile::MissingKeyError
    puts "Missing encryption key to decrypt secrets.yml."
    puts "Ask your team for your secrets key and put it in #{key_path}"
  rescue ActiveSupport::EncryptedFile::InvalidMessage
    puts "Invalid encryption key for secrets.yml."
  end

  desc "Show decrypted secrets.yml content"
  task show: :environment do
    secrets_path = Rails.root.join("config/secrets.yml")
    key_path = Rails.root.join("config/secrets.yml.key")

    unless secrets_path.exist?
      puts "Secrets file doesn't exist. Run 'rake secvault:setup' first."
      exit 1
    end

    encrypted_file = ActiveSupport::EncryptedFile.new(
      content_path: secrets_path,
      key_path: key_path,
      env_key: "RAILS_SECRETS_KEY",
      raise_if_missing_key: true
    )

    puts encrypted_file.read
  rescue ActiveSupport::EncryptedFile::MissingKeyError
    puts "Missing encryption key to decrypt secrets.yml."
    puts "Ask your team for your secrets key and put it in #{key_path}"
  rescue ActiveSupport::EncryptedFile::InvalidMessage
    puts "Invalid encryption key for secrets.yml."
  end
end
