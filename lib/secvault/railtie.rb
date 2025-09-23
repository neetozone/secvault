# frozen_string_literal: true

require "rails/railtie"

module Secvault
  class Railtie < Rails::Railtie
    railtie_name :secvault

    initializer "secvault.initialize", before: :load_environment_hook do |app|
      Secvault::Secrets.setup(app)
    end

    # Ensure initialization happens early in all environments
    config.before_configuration do |app|
      secrets_path = app.root.join("config/secrets.yml")

      if secrets_path.exist? && !Rails.application.respond_to?(:secrets)
        # Early initialization for test environment compatibility
        current_env = ENV["RAILS_ENV"] || "development"
        secrets = Secvault::Secrets.read_secrets(secrets_path, current_env)

        if secrets
          Rails.application.define_singleton_method(:secrets) do
            @secrets ||= begin
              current_secrets = ActiveSupport::OrderedOptions.new
              env_secrets = Secvault::Secrets.read_secrets(secrets_path, Rails.env)
              current_secrets.merge!(env_secrets) if env_secrets
              current_secrets
            end
          end
        end
      end
    end
  end
end
