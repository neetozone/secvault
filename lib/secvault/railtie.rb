# frozen_string_literal: true

require "rails/railtie"

module Secvault
  class Railtie < Rails::Railtie
    railtie_name :secvault

    initializer "secvault.initialize" do |app|
      Secvault::Secrets.setup(app)
    end

    generators do
      require "secvault/generators/secrets_generator"
    end

    rake_tasks do
      load "secvault/tasks.rake"
    end
  end
end
