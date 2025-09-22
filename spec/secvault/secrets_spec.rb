# frozen_string_literal: true

require "spec_helper"
require "tempfile"
require "pathname"

RSpec.describe Secvault::Secrets do
  describe ".read_secrets" do
    let(:temp_dir) { Dir.mktmpdir }
    let(:secrets_path) { Pathname.new(File.join(temp_dir, "secrets.yml")) }
    let(:key_path) { Pathname.new(File.join(temp_dir, "secrets.yml.key")) }

    after do
      FileUtils.rm_rf(temp_dir)
    end

    context "when secrets file doesn't exist" do
      it "returns empty hash" do
        result = described_class.read_secrets(secrets_path, key_path, "development")
        expect(result).to eq({})
      end
    end

    context "when secrets file exists as plain YAML" do
      before do
        secrets_content = <<~YAML
          development:
            secret_key_base: dev_secret
            api_key: dev_api_key

          test:
            secret_key_base: test_secret
            api_key: test_api_key

          production:
            secret_key_base: prod_secret
            api_key: prod_api_key
        YAML

        File.write(secrets_path, secrets_content)
      end

      it "returns secrets for the specified environment" do
        result = described_class.read_secrets(secrets_path, key_path, "development")

        expect(result).to eq({
          secret_key_base: "dev_secret",
          api_key: "dev_api_key"
        })
      end

      it "returns secrets for test environment" do
        result = described_class.read_secrets(secrets_path, key_path, "test")

        expect(result).to eq({
          secret_key_base: "test_secret",
          api_key: "test_api_key"
        })
      end

      it "returns empty hash for non-existent environment" do
        result = described_class.read_secrets(secrets_path, key_path, "staging")
        expect(result).to eq({})
      end
    end

    context "with ERB in secrets file" do
      before do
        ENV["TEST_SECRET"] = "erb_secret"

        secrets_content = <<~YAML
          development:
            secret_key_base: dev_secret
            erb_secret: <%= ENV['TEST_SECRET'] %>

          test:
            secret_key_base: test_secret
        YAML

        File.write(secrets_path, secrets_content)
      end

      after do
        ENV.delete("TEST_SECRET")
      end

      it "processes ERB templates" do
        result = described_class.read_secrets(secrets_path, key_path, "development")

        expect(result).to eq({
          secret_key_base: "dev_secret",
          erb_secret: "erb_secret"
        })
      end
    end
  end

  describe ".parse" do
    let(:temp_dir) { Dir.mktmpdir }
    let(:config_path) { Pathname.new(File.join(temp_dir, "config.yml")) }

    after do
      FileUtils.rm_rf(temp_dir)
    end

    context "when file exists" do
      before do
        config_content = <<~YAML
          development:
            key1: value1
            key2: value2

          test:
            key1: test_value1
        YAML

        File.write(config_path, config_content)
      end

      it "parses configuration for given environment" do
        result = described_class.parse([config_path], env: "development")

        expect(result).to eq({
          "key1" => "value1",
          "key2" => "value2"
        })
      end

      it "returns empty hash for non-existent environment" do
        result = described_class.parse([config_path], env: "staging")
        expect(result).to eq({})
      end
    end

    context "when file doesn't exist" do
      it "returns empty hash" do
        non_existent_path = Pathname.new(File.join(temp_dir, "non_existent.yml"))
        result = described_class.parse([non_existent_path], env: "development")

        expect(result).to eq({})
      end
    end
  end
end
