# frozen_string_literal: true

module Secvault
  class SecretsHelper
    def initialize(app)
      @app = app
      @secrets_path = app.root.join("config/secrets.yml")
      @key_path = app.root.join("config/secrets.yml.key")
    end

    def secrets
      @secrets ||= load_secrets
    end

    def [](key)
      secrets[key.to_sym]
    end

    def fetch(key, default = nil)
      secrets.fetch(key.to_sym, default)
    end

    def key?(key)
      secrets.key?(key.to_sym)
    end

    def empty?
      secrets.empty?
    end

    def to_h
      secrets.dup
    end

    private

    def load_secrets
      return {} unless @secrets_path.exist?

      env_secrets = Secvault::Secrets.read_secrets(@secrets_path, @key_path, Rails.env)
      env_secrets || {}
    end
  end
end
