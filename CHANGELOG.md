## [Unreleased]

## [2.3.0] - 2025-09-22

### Changed

- **Better method naming**: Renamed `setup_rails_71_integration!` to `setup_backward_compatibility_with_older_rails!`
- **More generic approach**: New method name works for any older Rails version, not just 7.1
- **Updated documentation**: README now uses "Older Rails Integration" instead of "Rails 7.1 Integration"
- **Clearer version support**: Documentation now shows "Rails 7.1 and older" for better clarity

### Backward Compatibility

- ✅ **Old method name still works**: `setup_rails_71_integration!` is aliased to the new method
- ✅ **No breaking changes**: All existing code continues to work
- ✅ **Updated test apps**: Rails 7.1 test app uses the new, cleaner method name

### Benefits

- **Future-proof naming**: Works for Rails 7.1, 7.0, 6.x, or any version with native secrets
- **Clearer intent**: Method name clearly indicates it's for backward compatibility
- **Better documentation**: More generic approach in README and code comments
- **Maintained compatibility**: Existing users don't need to change anything

## [2.2.0] - 2025-09-22

### Added

- **New simplified API**: `Rails::Secrets.load()` - cleaner method to load default config/secrets.yml
- **Enhanced README** with comprehensive examples for multiple files usage
- **Better documentation** showing how to parse custom files and multiple file merging
- **Backward compatibility aliases** - `parse_default` and `read` still work

### Changed

- **Improved method naming**: `Rails::Secrets.load()` is now the preferred method over `parse_default()`
- **Enhanced documentation** in code with clear examples for single file, multiple files, and custom paths
- **Better README examples** showing advanced usage patterns

### Examples Added

- Multiple secrets files merging: `Rails::Secrets.parse(['secrets.yml', 'secrets.local.yml'], env: Rails.env)`
- Environment-specific loading: `Rails::Secrets.load(env: 'production')`
- Custom file parsing: `Rails::Secrets.parse(['config/custom.yml'], env: Rails.env)`
- Multiple path support: `Rails::Secrets.parse([Rails.root.join('config', 'secrets.yml')], env: Rails.env)`

### Backward Compatibility

- ✅ All existing methods still work
- ✅ `parse_default` → `load` (alias maintained)
- ✅ `read` → `load` (alias maintained)
- ✅ No breaking changes

## [2.1.0] - 2025-09-22

### Removed

- **Removed all rake tasks** - Ultimate simplicity! No more `rake secvault:setup`, `rake secvault:edit`, or `rake secvault:show`
- Removed `lib/secvault/tasks.rake` file entirely
- Removed rake task loading from railtie

### Changed

- **Ultra-simple setup**: Just create `config/secrets.yml` with any text editor
- Updated README to reflect manual file creation instead of rake tasks
- Updated module documentation to show simple 3-step process
- Cleaner railtie without task loading complexity

### Benefits

- **Zero dependencies on rake tasks** - works with just plain YAML files
- **Even simpler** - no commands to remember, just edit YAML files
- **More intuitive** - developers already know how to create and edit YAML files
- **Less code** - removed unnecessary complexity

### Tested

- ✅ Rails 7.1 integration works perfectly
- ✅ Rails 8.0 automatic setup works perfectly
- ✅ No rake task conflicts or errors

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
