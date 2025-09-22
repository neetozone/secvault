# Secvault

Restores the classic Rails `secrets.yml` functionality that was removed in Rails 7.2. Uses simple, plain YAML files for environment-specific secrets management with powerful features like YAML defaults, ERB interpolation, and multi-file configurations.

**Rails Version Support:**
- **Rails 7.1 and older**: Manual setup (see Older Rails Integration below)
- **Rails 7.2+**: Automatic setup
- **Rails 8.0+**: Full compatibility

## Installation

```ruby
# Gemfile
gem 'secvault'
```

```bash
bundle install
```

## Quick Start (Rails 7.2+)

```bash
# 1. Create secrets.yml
touch config/secrets.yml

# 2. Edit with your favorite editor
$EDITOR config/secrets.yml
```

**Usage in your app:**
```ruby
Rails.application.secrets.api_key
Rails.application.secrets.database_password
```

**Example secrets.yml with YAML defaults and ERB:**
```yaml
# YAML defaults - inherited by all environments
default: &default
  app_name: "My Application"
  database:
    adapter: "postgresql"
    pool: 5
    timeout: 5000
  api:
    timeout: 30
    retries: 3

development:
  <<: *default  # Inherit defaults
  api_key: "dev_api_key_123"
  database:
    host: "localhost"
    name: "myapp_development"
  api:
    base_url: "http://localhost:3000"  # Override default

production:
  <<: *default  # Inherit defaults
  api_key: <%= ENV['API_KEY'] %>
  database:
    host: <%= ENV['DATABASE_HOST'] %>
    name: <%= ENV['DATABASE_NAME'] %>
    pool: <%= ENV.fetch('DATABASE_POOL', '10').to_i %>  # Type conversion
  api:
    base_url: <%= ENV['API_BASE_URL'] %>
  
  # Boolean conversion
  features:
    new_ui: <%= ENV.fetch('FEATURE_NEW_UI', 'true') == 'true' %>
  
  # Array conversion
  oauth_scopes: <%= ENV.fetch('OAUTH_SCOPES', 'email,profile').split(',') %>
```

## Multi-File Configuration

Organize secrets across multiple files with a **super clean API**:

```ruby
# config/initializers/secvault.rb
require "secvault"

# That's it! Just pass your files array
Secvault.setup_multi_file!([
  'config/secrets.yml',         # Base secrets
  'config/secrets.oauth.yml',   # OAuth & APIs
  'config/secrets.local.yml'    # Local overrides
])
```

**What this does:**
- ✅ Loads and merges all files in order (later files override earlier ones)
- ✅ Handles missing files gracefully
- ✅ Creates Rails.application.secrets with merged configuration

**Advanced options:**
```ruby
# Disable reload helper or logging
Secvault.setup_multi_file!(files, reload_method: false, logger: false)

# Use Pathname objects if needed
Secvault.setup_multi_file!([
  Rails.root.join('config', 'secrets.yml'),
  Rails.root.join('config', 'secrets.oauth.yml')
])
```

## Advanced Usage

**Manual multi-file parsing:**
```ruby
# Parse multiple files - later files override earlier ones
secrets = Rails::Secrets.parse([
  'config/secrets.yml',
  'config/secrets.oauth.yml',
  'config/secrets.local.yml'
], env: Rails.env)
```

**Load specific environment:**
```ruby
# Load production secrets in any environment
production_secrets = Rails::Secrets.load(env: 'production')

# Load development secrets
dev_secrets = Rails::Secrets.load(env: 'development')
```

**Environment-specific loading:**
```ruby
# Load production secrets in any environment
production_secrets = Rails::Secrets.load(env: 'production')

# Load development secrets
dev_secrets = Rails::Secrets.load(env: 'development')
```

## ERB Features & Type Conversion

Secvault supports ERB templating with automatic type conversion:

```yaml
production:
  # String interpolation
  api_key: <%= ENV['API_KEY'] %>
  
  # Integer conversion
  database_pool: <%= ENV.fetch('DB_POOL', '10').to_i %>
  
  # Boolean conversion  
  debug_enabled: <%= ENV.fetch('DEBUG', 'false') == 'true' %>
  
  # Array conversion
  allowed_hosts: <%= ENV.fetch('HOSTS', 'localhost,127.0.0.1').split(',') %>
  
  # Fallback values
  timeout: <%= ENV.fetch('TIMEOUT', '30').to_i %>
  adapter: <%= ENV.fetch('DB_ADAPTER', 'postgresql') %>
```

## Development Tools

**Hot-reload secrets (automatically available in development):**
```ruby
# In Rails console - automatically added by setup_multi_file!
reload_secrets!  # Reloads all configured files without server restart
# 🔄 Reloaded secrets from 3 files

# Also available as:
Rails.application.reload_secrets!
```

**Check integration status:**
```ruby
Secvault.active?  # Returns true if Secvault is managing secrets
```

## Older Rails Integration

For Rails versions with existing secrets functionality (like Rails 7.1), use Secvault to test before upgrading:

```ruby
# config/initializers/secvault.rb
Secvault.setup_backward_compatibility_with_older_rails!
```

This replaces Rails.application.secrets with Secvault functionality. Your existing Rails 7.1 code works unchanged:

```ruby
Rails.application.secrets.api_key          # ✅ Works
Rails.application.secrets.oauth_settings   # ✅ Works
Rails::Secrets.load                        # ✅ Load default config/secrets.yml
Rails::Secrets.parse(['custom.yml'], env: Rails.env)  # ✅ Parse custom files
```

**Check if Secvault is active:**
```ruby
if Secvault.active?
  puts "Using Secvault for secrets management"
else
  puts "Using default Rails secrets functionality"
end
```

## Usage Examples

**Basic usage:**
```ruby
# Access secrets
Rails.application.secrets.api_key
Rails.application.secrets.database.host
Rails.application.secrets.oauth.google.client_id

# With YAML defaults, you get deep merging:
Rails.application.secrets.database.adapter  # "postgresql" (from default)
Rails.application.secrets.database.host     # "localhost" (from environment)
```

## Security Best Practices

### ⚠️ Production Security
- **Never commit production secrets** to version control
- **Use environment variables** in production with ERB: `<%= ENV['SECRET'] %>`
- **Use ENV.fetch()** with fallbacks: `<%= ENV.fetch('SECRET', 'default') %>`

### 📝 File Management
- **Add sensitive files** to `.gitignore`:
  ```gitignore
  config/secrets.yml         # If contains sensitive data
  config/secrets.local.yml   # Local development overrides
  config/secrets.production.yml  # If used
  ```

### 🔑 Recommended Structure
```yaml
  production:
  api_key: <%= ENV['API_KEY'] %>  # ✅ From environment

# ❌ BAD: Secrets hardcoded in base file
production:
  api_key: "super_secret_production_key"  # ❌ Never do this
```

## License

MIT License - see [LICENSE](https://opensource.org/licenses/MIT)
