# frozen_string_literal: true

module Secvault
  # Rails::Secrets compatibility module
  # Provides the classic Rails::Secrets interface for backwards compatibility
  # This replicates the Rails < 7.2 Rails::Secrets module functionality
  module RailsSecrets
    extend self
    
    # Classic Rails::Secrets.parse method
    # 
    # Parses secrets files with support for:
    # - ERB templating 
    # - Shared sections that apply to all environments
    # - Environment-specific sections
    # - Deep symbolized keys
    #
    # Example usage:
    #   Rails::Secrets.parse([Pathname.new('config/secrets.yml')], env: 'development')
    #
    # Example secrets.yml structure:
    #   shared:
    #     common_key: shared_value
    #   
    #   development:
    #     secret_key_base: dev_secret
    #     api_key: dev_api_key
    #   
    #   production:
    #     secret_key_base: <%= ENV["SECRET_KEY_BASE"] %>
    #     api_key: <%= ENV["API_KEY"] %>
    #
    def parse(paths, env:)
      Secvault::Secrets.parse(paths, env: env.to_s)
    end
    
    # Convenience method to parse the default secrets file
    def parse_default(env: Rails.env)
      secrets_path = Rails.root.join("config/secrets.yml")
      parse([secrets_path], env: env)
    end
    
    # Read and parse secrets for the current Rails environment
    def read(env: Rails.env)
      parse_default(env: env)
    end
  end
end

# Monkey patch to restore Rails::Secrets interface for backwards compatibility
# Only for Rails 7.2+ where Rails::Secrets was removed
if defined?(Rails) && Rails.respond_to?(:version)
  rails_version = Rails.version
  major, minor = rails_version.split('.').map(&:to_i)
  
  # Only alias for Rails 7.2+ to avoid conflicts with native Rails::Secrets in 7.1
  if major > 7 || (major == 7 && minor >= 2)
    module Rails
      Secrets = Secvault::RailsSecrets
    end
  end
end
