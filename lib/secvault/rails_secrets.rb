# frozen_string_literal: true

module Secvault
  # Rails::Secrets compatibility module
  # Provides the classic Rails::Secrets interface for backwards compatibility
  # This replicates the Rails < 7.2 Rails::Secrets module functionality
  module RailsSecrets
    extend self

    # Parse secrets from one or more YAML files
    #
    # Supports:
    # - ERB templating for environment variables
    # - Shared sections that apply to all environments
    # - Environment-specific sections
    # - Multiple files (merged in order)
    # - Deep symbolized keys
    #
    # Examples:
    #   # Single file
    #   Rails::Secrets.parse(['config/secrets.yml'], env: 'development')
    #
    #   # Multiple files (merged in order)
    #   Rails::Secrets.parse([
    #     'config/secrets.yml',
    #     'config/secrets.local.yml'
    #   ], env: 'development')
    #
    #   # Load default config/secrets.yml
    #   Rails::Secrets.load  # uses current Rails.env
    #   Rails::Secrets.load(env: 'production')
    def parse(paths, env:)
      Secvault::Secrets.parse(paths, env: env.to_s)
    end

    # Load secrets from the default config/secrets.yml file
    def load(env: Rails.env)
      secrets_path = Rails.root.join("config/secrets.yml")
      parse([secrets_path], env: env)
    end

    # Backward compatibility aliases (deprecated)
    alias_method :parse_default, :load
    alias_method :read, :load
  end
end

# Monkey patch to restore Rails::Secrets interface for backwards compatibility
# Works consistently across all Rails versions with warning suppression
if defined?(Rails)
  module Rails
    Secrets = Secvault::RailsSecrets
  end
end
