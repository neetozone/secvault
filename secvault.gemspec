# frozen_string_literal: true

require_relative "lib/secvault/version"

Gem::Specification.new do |spec|
  spec.name = "secvault"
  spec.version = Secvault::VERSION
  spec.authors = ["Unnikrishnan KP"]
  spec.email = ["unnikrishnan.kp@bigbinary.com"]

  spec.summary = "Simple Rails secrets.yml functionality for Rails 7.1+, 7.2+ and Rails 8.0+"
  spec.description = "Secvault restores the classic Rails secrets.yml functionality that was removed in Rails 7.2, using simple, plain YAML files for environment-specific secrets management. Compatible with Rails 7.1+, 7.2+ and 8.0+."
  spec.homepage = "https://github.com/unnitallman/secvault"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/unnitallman/secvault"
  spec.metadata["changelog_uri"] = "https://github.com/unnitallman/secvault/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Rails 7.1+, 7.2+ and 8.0+ dependency
  spec.add_dependency "rails", ">= 7.1.0"
  spec.add_dependency "zeitwerk", "~> 2.6"
  # Development dependencies for testing
  spec.add_development_dependency "rspec_junit_formatter", "~> 0.6"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
