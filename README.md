# Secvault

Secvault restores the classic Rails `secrets.yml` functionality using simple, plain YAML files for environment-specific secrets management. Compatible with all modern Rails versions (7.1+, 7.2+, 8.0+) with automatic deprecation warning suppression.

[![Gem Version](https://img.shields.io/gem/v/secvault.svg)](https://rubygems.org/gems/secvault)

## Why Secvault?

- **Drop-in replacement** for Rails 7.2+'s removed `secrets.yml` functionality
- **Universal compatibility** across Rails 7.1+, 7.2+, and 8.0+
- **Automatic warning suppression** - no more deprecation warnings
- **ERB templating** support for environment variables
- **Multi-file support** with deep merging capabilities
- **Shared sections** for common configuration across environments
- **Simple YAML** - no complex credential management required

## Installation

```ruby
# Gemfile
gem 'secvault'
```

```bash
bundle install
```

## Quick Start

### 1. Simple Setup

Create `config/initializers/secvault.rb`:

```ruby
# The simplest setup - works across all Rails versions
Secvault.setup!
```

Create `config/secrets.yml`:

```yaml
shared:
  app_name: "My Rails App"
  timeout: 30

development:
  secret_key_base: "dev_secret_key_here"
  api_key: "dev_key_123"
  database_url: "postgresql://localhost/myapp_dev"
  debug: true

test:
  secret_key_base: "test_secret_key_here"
  api_key: "test_key_123"

production:
  secret_key_base: <%= ENV['SECRET_KEY_BASE'] %>
  api_key: <%= ENV['API_KEY'] %>
  database_url: <%= ENV['DATABASE_URL'] %>
  debug: false
```

### 2. Access Your Secrets

```ruby
# In your Rails application
Rails.application.secrets.api_key
Rails.application.secrets.app_name
Rails.application.secrets.database_url

# Nested secrets work too
Rails.application.secrets.database.host
Rails.application.secrets.features.analytics
```

## Setup Methods

### Universal Setup

```ruby
# Works for all Rails versions with sensible defaults
Secvault.setup!

# With options
Secvault.setup!(
  suppress_warnings: true,      # Default: true
  set_secret_key_base: true     # Default: true
)
```

### Multi-File Setup

Perfect for organizing secrets across multiple files:

```ruby
# Load and merge multiple secrets files
Secvault.setup_multi_file!([
  'config/secrets.yml',
  'config/secrets.oauth.yml', 
  'config/secrets.local.yml'   # Git-ignored local overrides
])

# With full options
Secvault.setup_multi_file!(
  ['config/secrets.yml', 'config/secrets.local.yml'],
  suppress_warnings: true,      # Default: true
  set_secret_key_base: true,    # Default: true
  reload_method: true,          # Default: true in development
  logger: true                  # Default: true except in production
)
```

### Standalone Usage (Advanced)

For cases where you want to load secrets without Rails integration:

```ruby
# Load secrets into Secvault.secrets without Rails integration
Secvault.start!(files: ['config/secrets.yml'])

# Access via Secvault.secrets instead of Rails.application.secrets
Secvault.secrets.api_key
Secvault.secrets.database_url

# Integrate with Rails later if needed
Secvault.integrate_with_rails!
```

## Advanced Features

### ERB Templating

Secvault supports full ERB templating for dynamic configuration:

```yaml
production:
  secret_key_base: <%= ENV['SECRET_KEY_BASE'] %>
  api_key: <%= ENV['API_KEY'] %>
  pool_size: <%= ENV.fetch('DB_POOL', '5').to_i %>
  
  # Complex expressions
  features:
    enabled: <%= ENV.fetch('FEATURES_ON', 'false') == 'true' %>
    analytics: <%= Rails.env.production? && ENV['ANALYTICS'] != 'false' %>
  
  # Arrays and complex data structures
  allowed_hosts: <%= ENV.fetch('ALLOWED_HOSTS', 'localhost').split(',') %>
  
  # Conditional values
  redis_url: <%=
    if ENV['REDIS_URL']
      ENV['REDIS_URL']
    else
      "redis://localhost:6379/#{Rails.env}"
    end
  %>
```

### Shared Sections

Define common secrets that apply to all environments:

```yaml
shared:
  app_name: "MyApp"
  version: "2.1.0"
  timeout: 30
  features:
    analytics: true
    
development:
  secret_key_base: "dev_secret"
  features:
    debug: true    # Merges with shared.features
    
production:
  secret_key_base: <%= ENV['SECRET_KEY_BASE'] %>
  features:
    analytics: false  # Overrides shared.features.analytics
```

### Multi-File Configuration

Organize your secrets across multiple files for better maintainability:

```ruby
Secvault.setup_multi_file!([
  'config/secrets.yml',           # Base secrets
  'config/secrets.oauth.yml',     # OAuth provider settings
  'config/secrets.database.yml',  # Database configurations
  'config/secrets.local.yml'      # Local overrides (git-ignored)
])
```

**File merging behavior:**
- Files are processed in order
- Later files override earlier ones
- Deep merging for nested hashes
- Shared sections are merged first, then environment-specific

### Development Helpers

In development mode, Secvault provides helpful reload methods:

```ruby
# Reload secrets without restarting Rails
reload_secrets!

# Or via Rails.application
Rails.application.reload_secrets!
```

## Manual API

For advanced use cases, you can use the lower-level API:

```ruby
# Parse specific files
secrets = Rails::Secrets.parse(['config/secrets.yml'], env: 'production')

# Load from default location
secrets = Rails::Secrets.load(env: 'development')

# Check if Secvault is active
Secvault.active?  # => true/false

# Check if integrated with Rails
Secvault.rails_integrated?  # => true/false

# Access loaded secrets directly
Secvault.secrets.api_key  # Available after Secvault.start!
```

## Deprecation Warning Suppression

**Secvault automatically suppresses Rails deprecation warnings** about `secrets.yml` usage. This provides:

- **Clean logs** - No more deprecation warnings cluttering your development/test output
- **Universal compatibility** - Works consistently across all Rails versions
- **Performance** - Avoids Rails' internal deprecation handling overhead

You can control this behavior:

```ruby
# Disable automatic warning suppression
Secvault.setup!(suppress_warnings: false)

# Or for multi-file setup
Secvault.setup_multi_file!(['config/secrets.yml'], suppress_warnings: false)
```

## Rails Version Compatibility

| Rails Version | Support Level | Notes |
|---------------|---------------|-------|
| **Rails 7.1+** | ✅ Full compatibility | Manual setup required |
| **Rails 7.2+** | ✅ Drop-in replacement | Automatic setup works |
| **Rails 8.0+** | ✅ Full compatibility | Future-proof |

### Rails 7.2+ Notes
Rails 7.2 removed the built-in `secrets.yml` functionality. Secvault provides a complete replacement with the same API.

### Rails 7.1 Notes
Rails 7.1 still has `secrets.yml` support but shows deprecation warnings. Secvault suppresses these warnings and provides a consistent experience.

## Migration Guide

### From Rails < 7.2 Built-in Secrets

1. **Add Secvault to your Gemfile**:
   ```ruby
   gem 'secvault'
   ```

2. **Create initializer**:
   ```ruby
   # config/initializers/secvault.rb
   Secvault.setup!
   ```

3. **Your existing `config/secrets.yml` works as-is** - no changes needed!

### From Rails Credentials

1. **Extract your credentials to YAML**:
   ```bash
   # Export existing credentials
   rails credentials:show > config/secrets.yml
   ```

2. **Format as environment-specific YAML**:
   ```yaml
   development:
     secret_key_base: "your_dev_secret"
     # ... other secrets
   
   production:
     secret_key_base: <%= ENV['SECRET_KEY_BASE'] %>
     # ... other secrets
   ```

3. **Set up Secvault**:
   ```ruby
   # config/initializers/secvault.rb
   Secvault.setup!
   ```

## Configuration Examples

### Basic Application

```yaml
# config/secrets.yml
shared:
  app_name: "MyApp"
  
development:
  secret_key_base: "long_random_string_for_dev"
  database_url: "postgresql://localhost/myapp_dev"
  
test:
  secret_key_base: "long_random_string_for_test"
  database_url: "postgresql://localhost/myapp_test"
  
production:
  secret_key_base: <%= ENV['SECRET_KEY_BASE'] %>
  database_url: <%= ENV['DATABASE_URL'] %>
```

### Multi-Service Application

```ruby
# config/initializers/secvault.rb
Secvault.setup_multi_file!([
  'config/secrets.yml',
  'config/secrets.oauth.yml',
  'config/secrets.external_apis.yml',
  'config/secrets.local.yml'  # Git-ignored
])
```

```yaml
# config/secrets.yml (base)
shared:
  app_name: "MyApp"
  timeout: 30

development:
  secret_key_base: "dev_secret"
  debug: true

production:
  secret_key_base: <%= ENV['SECRET_KEY_BASE'] %>
  debug: false
```

```yaml
# config/secrets.oauth.yml
shared:
  oauth:
    google:
      scope: "email profile"

development:
  oauth:
    google:
      client_id: "dev_google_client_id"
      client_secret: "dev_google_client_secret"

production:
  oauth:
    google:
      client_id: <%= ENV['GOOGLE_CLIENT_ID'] %>
      client_secret: <%= ENV['GOOGLE_CLIENT_SECRET'] %>
```

## Troubleshooting

### Common Issues

**1. "No secrets.yml file found"**
```bash
# Create the file
mkdir -p config
touch config/secrets.yml
```

**2. "undefined method `secrets' for Rails.application"**
```ruby
# Make sure Secvault is set up in an initializer
# config/initializers/secvault.rb
Secvault.setup!
```

**3. "Secrets not loading in tests"**
```ruby
# In your test helper or rails_helper.rb
Secvault.setup! if defined?(Secvault)
```

**4. "Environment variables not working"**
```yaml
# Make sure you're using ERB syntax
production:
  api_key: <%= ENV['API_KEY'] %>  # ✅ Correct
  api_key: $API_KEY               # ❌ Wrong
```

### Debug Mode

```ruby
# Enable detailed logging (development/test only)
Secvault.setup_multi_file!(['config/secrets.yml'], logger: true)

# Check if Secvault is working
Secvault.active?           # Should return true
Secvault.rails_integrated? # Should return true
Rails.application.secrets  # Should show your secrets
```

## API Reference

### Setup Methods

- `Secvault.setup!(suppress_warnings: true, set_secret_key_base: true)`
- `Secvault.setup_multi_file!(files, **options)`
- `Secvault.start!(files: [], logger: true)` 
- `Secvault.integrate_with_rails!`

### Status Methods

- `Secvault.active?` - Check if secrets are loaded
- `Secvault.rails_integrated?` - Check if Rails integration is active
- `Secvault.secrets` - Access loaded secrets directly

### Rails API Compatibility

- `Rails::Secrets.parse(files, env:)` - Parse specific files
- `Rails::Secrets.load(env:)` - Load from default config/secrets.yml
- `Rails.application.secrets` - Access secrets (same as classic Rails)

### Legacy Aliases

- `Secvault.setup_backward_compatibility_with_older_rails!` (alias for `setup!`)
- `Secvault.setup_rails_71_integration!` (alias for `setup!`)
- `Secvault.setup_multi_files!` (alias for `setup_multi_file!`)

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

MIT License. See [LICENSE](LICENSE) for details.
