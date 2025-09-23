# frozen_string_literal: true

require_relative "spec_helper"
require_relative "../lib/secvault/secrets"
require "pathname"

RSpec.describe Secvault::Secrets do
  let(:temp_dir) { nil }

  after { cleanup_temp_dir(temp_dir) if temp_dir }

  describe ".parse" do
    context "with basic YAML structure" do
      let(:yaml_content) do
        <<~YAML
          development:
            secret_key_base: dev_secret_key
            api_key: dev_api_key
            database:
              host: localhost
              port: 5432

          test:
            secret_key_base: test_secret_key
            api_key: test_api_key

          production:
            secret_key_base: prod_secret_key
            api_key: prod_api_key
        YAML
      end

      let(:secrets_file_data) { create_temp_yaml_file(yaml_content) }
      let(:secrets_file) { secrets_file_data[0] }
      let(:temp_dir) { secrets_file_data[1] }

      it "parses secrets for development environment" do
        result = described_class.parse([secrets_file], env: "development")

        expect(result).to eq({
          secret_key_base: "dev_secret_key",
          api_key: "dev_api_key",
          database: {
            host: "localhost",
            port: 5432
          }
        })
      end

      it "parses secrets for test environment" do
        result = described_class.parse([secrets_file], env: "test")

        expect(result).to eq({
          secret_key_base: "test_secret_key",
          api_key: "test_api_key"
        })
      end

      it "returns empty hash for non-existent environment" do
        result = described_class.parse([secrets_file], env: "staging")
        expect(result).to eq({})
      end
    end

    context "with YAML anchors" do
      let(:yaml_content) do
        <<~YAML
          defaults: &defaults
            app_name: "Test Application"
            timeout: 30
            features:
              analytics: true

          development:
            <<: *defaults
            secret_key_base: dev_secret
            features:
              debug: true

          test:
            <<: *defaults
            secret_key_base: test_secret
        YAML
      end

      let(:secrets_file_data) { create_temp_yaml_file(yaml_content) }
      let(:secrets_file) { secrets_file_data[0] }
      let(:temp_dir) { secrets_file_data[1] }

      it "merges YAML anchors with environment-specific sections" do
        result = described_class.parse([secrets_file], env: "development")

        expect(result).to eq({
          app_name: "Test Application",
          timeout: 30,
          features: {
            debug: true  # Note: YAML anchors replace, don't merge nested objects
          },
          secret_key_base: "dev_secret"
        })
      end

      it "includes YAML anchor defaults for environments" do
        result = described_class.parse([secrets_file], env: "test")

        expect(result).to eq({
          app_name: "Test Application",
          timeout: 30,
          features: {
            analytics: true
          },
          secret_key_base: "test_secret"
        })
      end
    end

    context "with ERB templating" do
      let(:yaml_content) do
        <<~YAML
          development:
            secret_key_base: dev_secret
            api_key: <%= ENV['DEV_API_KEY'] || 'default_dev_key' %>
            database_url: <%= ENV['DATABASE_URL'] %>

          production:
            secret_key_base: <%= ENV['SECRET_KEY_BASE'] %>
            api_key: <%= ENV['API_KEY'] %>
        YAML
      end

      let(:secrets_file_data) { create_temp_yaml_file(yaml_content) }
      let(:secrets_file) { secrets_file_data[0] }
      let(:temp_dir) { secrets_file_data[1] }

      it "processes ERB templates with environment variables" do
        with_env_vars({
          "DEV_API_KEY" => "test_api_key",
          "DATABASE_URL" => "postgresql://localhost/test"
        }) do
          result = described_class.parse([secrets_file], env: "development")

          expect(result[:api_key]).to eq("test_api_key")
          expect(result[:database_url]).to eq("postgresql://localhost/test")
          expect(result[:secret_key_base]).to eq("dev_secret")
        end
      end

      it "handles missing environment variables gracefully" do
        result = described_class.parse([secrets_file], env: "development")

        expect(result[:api_key]).to eq("default_dev_key")
        expect(result[:database_url]).to be_nil
      end
    end

    context "with multiple files" do
      let(:base_yaml) do
        <<~YAML
          development:
            secret_key_base: base_dev_secret
            api_key: base_api_key
            database:
              host: localhost
              port: 5432
        YAML
      end

      let(:override_yaml) do
        <<~YAML
          development:
            api_key: override_api_key
            database:
              port: 3306
              ssl: true
            new_feature: enabled
        YAML
      end

      let(:base_file_data) { create_temp_yaml_file(base_yaml, "base.yml") }
      let(:base_file) { base_file_data[0] }
      let(:temp_dir1) { base_file_data[1] }
      let(:override_file_data) { create_temp_yaml_file(override_yaml, "override.yml") }
      let(:override_file) { override_file_data[0] }
      let(:temp_dir2) { override_file_data[1] }

      after do
        cleanup_temp_dir(temp_dir1)
        cleanup_temp_dir(temp_dir2)
      end

      it "merges multiple files with later files taking precedence" do
        result = described_class.parse([base_file, override_file], env: "development")

        expect(result).to eq({
          secret_key_base: "base_dev_secret", # From base
          api_key: "override_api_key", # Override wins
          database: {
            host: "localhost", # From base
            port: 3306, # Override wins
            ssl: true # Added from override
          },
          new_feature: "enabled" # Added from override
        })
      end
    end

    context "with non-existent files" do
      it "handles missing files gracefully" do
        non_existent = Pathname.new("/non/existent/file.yml")
        result = described_class.parse([non_existent], env: "development")

        expect(result).to eq({})
      end

      it "processes existing files and skips missing ones" do
        secrets_file, temp_dir = create_temp_yaml_file("development:\n  existing_key: value")
        missing_file = Pathname.new("/missing/file.yml")

        result = described_class.parse([secrets_file, missing_file], env: "development")

        expect(result).to eq({existing_key: "value"})
        cleanup_temp_dir(temp_dir)
      end
    end

    context "with empty files" do
      let(:secrets_file_data) { create_temp_yaml_file("") }
      let(:secrets_file) { secrets_file_data[0] }
      let(:temp_dir) { secrets_file_data[1] }

      it "handles empty files gracefully" do
        result = described_class.parse([secrets_file], env: "development")
        expect(result).to eq({})
      end
    end
  end

  describe ".read_secrets" do
    context "with existing file" do
      let(:yaml_content) do
        <<~YAML
          development:
            secret_key_base: dev_secret
            api_key: dev_api

          test:
            secret_key_base: test_secret
            api_key: test_api
        YAML
      end

      let(:secrets_file_data) { create_temp_yaml_file(yaml_content) }
      let(:secrets_file) { secrets_file_data[0] }
      let(:temp_dir) { secrets_file_data[1] }

      it "reads secrets for specified environment" do
        result = described_class.read_secrets(secrets_file, "development")

        expect(result).to eq({
          secret_key_base: "dev_secret",
          api_key: "dev_api"
        })
      end

      it "returns empty hash for non-existent environment" do
        result = described_class.read_secrets(secrets_file, "production")
        expect(result).to eq({})
      end
    end

    context "with ERB content" do
      let(:yaml_content) do
        <<~YAML
          development:
            api_key: <%= ENV['TEST_API_KEY'] || 'default' %>
            timeout: <%= ENV.fetch('TIMEOUT', '30').to_i %>
        YAML
      end

      let(:secrets_file_data) { create_temp_yaml_file(yaml_content) }
      let(:secrets_file) { secrets_file_data[0] }
      let(:temp_dir) { secrets_file_data[1] }

      it "processes ERB templates" do
        with_env_vars({"TEST_API_KEY" => "erb_key", "TIMEOUT" => "60"}) do
          result = described_class.read_secrets(secrets_file, "development")

          expect(result[:api_key]).to eq("erb_key")
          expect(result[:timeout]).to eq(60)
        end
      end
    end

    context "with non-existent file" do
      it "returns empty hash" do
        non_existent = Pathname.new("/non/existent/file.yml")
        result = described_class.read_secrets(non_existent, "development")

        expect(result).to eq({})
      end
    end
  end
end
