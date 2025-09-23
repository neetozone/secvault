# frozen_string_literal: true

require "tempfile"
require "fileutils"

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Helper methods for creating test files
  config.include Module.new {
    def create_temp_yaml_file(content, filename = "secrets.yml")
      temp_dir = Dir.mktmpdir
      file_path = File.join(temp_dir, filename)
      File.write(file_path, content)
      [Pathname.new(file_path), temp_dir]
    end

    def cleanup_temp_dir(temp_dir)
      FileUtils.rm_rf(temp_dir) if temp_dir && Dir.exist?(temp_dir)
    end

    def with_env_vars(vars)
      original_values = {}
      vars.each do |key, value|
        original_values[key] = ENV[key]
        ENV[key] = value
      end
      yield
    ensure
      original_values.each do |key, value|
        if value.nil?
          ENV.delete(key)
        else
          ENV[key] = value
        end
      end
    end
  }
end
