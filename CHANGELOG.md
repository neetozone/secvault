## [Unreleased]

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
