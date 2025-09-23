# frozen_string_literal: true

require_relative "spec_helper"
require_relative "../lib/secvault/rails_secrets"
require "pathname"

# Mock Rails for testing
class MockRails
  class << self
    attr_accessor :root

    def env
      "test"
    end
  end

  self.root = Pathname.new("/tmp")
end

# Set up Rails constant for testing
Rails = MockRails unless defined?(Rails)

RSpec.describe Secvault::RailsSecrets do
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

      it "delegates to Secvault::Secrets.parse" do
        expect(Secvault::Secrets).to receive(:parse).with([secrets_file], env: "development")
        described_class.parse([secrets_file], env: "development")
      end

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

      it "handles string environment parameter" do
        result = described_class.parse([secrets_file], env: "development")
        expect(result[:secret_key_base]).to eq("dev_secret_key")
      end

      it "handles symbol environment parameter" do
        result = described_class.parse([secrets_file], env: :development)
        expect(result[:secret_key_base]).to eq("dev_secret_key")
      end
    end

    context "with shared sections" do
      let(:yaml_content) do
        <<~YAML
          shared:
            app_name: "Test Application"
            timeout: 30
            features:
              analytics: true

          development:
            secret_key_base: dev_secret
            features:
              debug: true

          test:
            secret_key_base: test_secret
        YAML
      end

      let(:secrets_file_data) { create_temp_yaml_file(yaml_content) }
      let(:secrets_file) { secrets_file_data[0] }
      let(:temp_dir) { secrets_file_data[1] }

      it "merges shared sections with environment-specific sections" do
        result = described_class.parse([secrets_file], env: "development")

        expect(result).to eq({
          app_name: "Test Application",
          timeout: 30,
          features: {
            analytics: true,
            debug: true
          },
          secret_key_base: "dev_secret"
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

      it "processes ERB templates" do
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
  end

  describe ".load" do
    before do
      # Create a mock config/secrets.yml in a temp directory
      @config_temp_dir = Dir.mktmpdir
      Rails.root = Pathname.new(@config_temp_dir)

      config_dir = File.join(@config_temp_dir, "config")
      FileUtils.mkdir_p(config_dir)
      @config_secrets_file = File.join(config_dir, "secrets.yml")
    end

    after do
      FileUtils.rm_rf(@config_temp_dir) if @config_temp_dir
    end

    context "with existing config/secrets.yml" do
      let(:yaml_content) do
        <<~YAML
          development:
            secret_key_base: config_dev_secret
            api_key: config_dev_api

          test:
            secret_key_base: config_test_secret
            api_key: config_test_api

          production:
            secret_key_base: config_prod_secret
            api_key: config_prod_api
        YAML
      end

      before do
        File.write(@config_secrets_file, yaml_content)
      end

      it "loads from default config/secrets.yml using current Rails.env" do
        result = described_class.load

        expect(result).to eq({
          secret_key_base: "config_test_secret",
          api_key: "config_test_api"
        })
      end

      it "loads from specific environment when env parameter is provided" do
        result = described_class.load(env: "production")

        expect(result).to eq({
          secret_key_base: "config_prod_secret",
          api_key: "config_prod_api"
        })
      end

      it "handles symbol environment parameter" do
        result = described_class.load(env: :development)

        expect(result).to eq({
          secret_key_base: "config_dev_secret",
          api_key: "config_dev_api"
        })
      end

      it "delegates to parse method correctly" do
        expected_path = Rails.root.join("config/secrets.yml")

        expect(described_class).to receive(:parse).with([expected_path], env: "development")

        described_class.load(env: "development")
      end
    end

    context "when config/secrets.yml doesn't exist" do
      it "returns empty hash" do
        result = described_class.load(env: "development")
        expect(result).to eq({})
      end
    end
  end

  describe "backward compatibility aliases" do
    before do
      @config_temp_dir = Dir.mktmpdir
      Rails.root = Pathname.new(@config_temp_dir)

      config_dir = File.join(@config_temp_dir, "config")
      FileUtils.mkdir_p(config_dir)
      config_secrets_file = File.join(config_dir, "secrets.yml")
      File.write(config_secrets_file, "development:\n  key: value")
    end

    after do
      FileUtils.rm_rf(@config_temp_dir) if @config_temp_dir
    end

    describe ".parse_default" do
      it "is an alias for load" do
        expect(described_class.method(:parse_default)).to eq(described_class.method(:load))
      end

      it "works the same as load" do
        result = described_class.parse_default(env: "development")
        expect(result[:key]).to eq("value")
      end
    end

    describe ".read" do
      it "is an alias for load" do
        expect(described_class.method(:read)).to eq(described_class.method(:load))
      end

      it "works the same as load" do
        result = described_class.read(env: "development")
        expect(result[:key]).to eq("value")
      end
    end
  end
end
