# frozen_string_literal: true

require "securerandom"

namespace :secvault do
  desc "Create a plain YAML secrets.yml file"
  task setup: :environment do
    secrets_path = Rails.root.join("config/secrets.yml")

    if secrets_path.exist?
      puts "Secrets file already exists at #{secrets_path}"
    else
      default_content = <<~YAML
        # Plain YAML secrets file
        # Environment-specific secrets for your Rails application
        #
        # For production, use environment variables with ERB syntax:
        # production:
        #   api_key: <%= ENV['API_KEY'] %>

        development:
          secret_key_base: #{SecureRandom.hex(64)}
          # Add your development secrets here
          # api_key: dev_key
          # database_password: dev_password

        test:
          secret_key_base: #{SecureRandom.hex(64)}
          # Add your test secrets here
          # api_key: test_key

        production:
          secret_key_base: <%= ENV["SECRET_KEY_BASE"] %>
          # Use environment variables for production secrets
          # api_key: <%= ENV["API_KEY"] %>
          # database_password: <%= ENV["DATABASE_PASSWORD"] %>
      YAML

      File.write(secrets_path, default_content)
      puts "✅ Created plain secrets.yml file at #{secrets_path}"
      puts "⚠️  Remember to add production secrets as environment variables"
      puts "⚠️  Never commit production secrets to version control"
    end
  end

  desc "Edit the plain YAML secrets.yml file"
  task edit: :environment do
    secrets_path = Rails.root.join("config/secrets.yml")

    unless secrets_path.exist?
      puts "Secrets file doesn't exist. Run 'rake secvault:setup' first."
      exit 1
    end

    # Open the plain YAML file in editor
    editor = ENV["EDITOR"] || "vi"
    system("#{editor} #{secrets_path}")
    puts "📝 Updated #{secrets_path}"
  end

  desc "Show the plain YAML secrets.yml content"
  task show: :environment do
    secrets_path = Rails.root.join("config/secrets.yml")

    unless secrets_path.exist?
      puts "Secrets file doesn't exist. Run 'rake secvault:setup' first."
      exit 1
    end

    puts "📄 Contents of #{secrets_path}:"
    puts "#{'=' * 50}"
    puts File.read(secrets_path)
    puts "#{'=' * 50}"
  end
end
