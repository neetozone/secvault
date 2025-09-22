## [Unreleased]

## [2.0.0] - 2025-09-22

### BREAKING CHANGES

- **Removed all encryption functionality** - Secvault now focuses purely on plain YAML secrets management
- Removed ActiveSupport::EncryptedFile dependencies
- Removed MissingKeyError and InvalidKeyError exceptions
- Removed `encrypted?`, `decrypt`, `decrypt_secrets` methods
- Simplified rake tasks to work with plain YAML only

### Added

- Simplified `rake secvault:setup` that creates plain YAML files with helpful comments
- Better error messages and user guidance in rake tasks
- Cleaner, more focused codebase without encryption complexity

### Changed

- **Major simplification**: All secrets are now stored in plain YAML files
- Updated README to reflect plain YAML approach
- Updated module documentation and gemspec descriptions
- Rake tasks now use emojis and better user experience
- Production secrets should use ERB syntax with environment variables

### Benefits

- Much simpler gem with single focus: plain YAML secrets management
- No encryption keys to manage or lose
- Easy to understand, edit, and debug secrets files
- Perfect for development and test environments
- Production secrets via environment variables (recommended best practice)

## [1.0.4] - 2025-09-22

### Added

- Comprehensive Rails 7.1 integration support
- New `Secvault.setup_rails_71_integration!` helper method for easy Rails 7.1 setup
- Enhanced documentation with Rails 7.1 integration guide
- Module-level documentation with usage examples and version compatibility

### Improved

- Better Rails 7.1 compatibility with automatic detection and setup
- Enhanced README with Rails 7.1 integration section
- Improved error handling and logging for Rails 7.1 integration
- More comprehensive inline documentation

### Changed

- Refined automatic setup logic to avoid conflicts with Rails 7.1 native functionality
- Updated gemspec description to include Rails 7.1+ support

## [1.0.3] - 2025-09-22

### Fixed

- Rails 7.1 compatibility issues with native Rails::Secrets conflicts
- String path handling in parse method
- Zeitwerk constant name mismatch resolution

### Added

- Manual setup method for Rails 7.1 (opt-in)
- Rails version detection for automatic setup decisions
- Only create Rails::Secrets alias for Rails 7.2+ to avoid conflicts

## [1.0.2] - 2025-09-22

### Changed

- Updated Rails dependency from >= 7.2.0 to >= 7.1.0 for broader compatibility
- Updated gem description to include Rails 7.1+ support

## [1.0.1] - 2025-09-22

### Fixed

- Zeitwerk constant name mismatch in rails_secrets.rb
- Changed module definition from Rails::Secrets to Secvault::RailsSecrets
- Added Rails::Secrets alias for backward compatibility
- Resolved Zeitwerk::NameError when loading Rails applications

## [1.0.0] - 2025-09-22

### Added

- Initial release of Secvault gem
- Rails secrets.yml functionality for Rails 7.2+
- Encrypted secrets.yml support using Rails' built-in encryption
- Environment-specific secrets management
- ERB template support in secrets files
- Rake tasks for secrets management:
  - `rake secvault:setup` - Create encrypted secrets file
  - `rake secvault:edit` - Edit encrypted secrets
  - `rake secvault:show` - Display decrypted secrets
- Rails generator for creating secrets files
- Automatic integration with Rails.application.secrets
- Support for both encrypted and plain YAML secrets files
- Key management with config/secrets.yml.key
- Environment variable fallback for encryption key
- Comprehensive error handling for missing/invalid keys
- Full test coverage with RSpec
- Detailed documentation and usage examples
