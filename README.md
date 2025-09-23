# Secvault

Restores Rails `secrets.yml` functionality for environment-specific secrets management using YAML files with ERB templating.

## Rails Version Support

- **Rails 7.2+**: Automatic setup (drop-in replacement for removed functionality)
- **Rails 7.1**: Manual setup required
- **Rails 8.0+**: Full compatibility

## Installation

```ruby
# Gemfile
gem 'secvault'
```

## Quick Start

Create `config/secrets.yml`:

```yaml
development:
  api_key: "dev_key_123"
  database_url: "postgresql://localhost/myapp_dev"

production:
  api_key: <%= ENV['API_KEY'] %>
  database_url: <%= ENV['DATABASE_URL'] %>
```

Access secrets in your app:

```ruby
Rails.application.secrets.api_key
Rails.application.secrets.database_url
```

## Multi-File Configuration

Load and merge multiple secrets files:

```ruby
# config/initializers/secvault.rb
Secvault.setup_multi_file!([
  'config/secrets.yml',
  'config/secrets.oauth.yml',
  'config/secrets.local.yml'
])
```

Files are merged in order with deep merge support for nested hashes.

## Manual API

```ruby
# Parse specific files
secrets = Rails::Secrets.parse(['config/secrets.yml'], env: Rails.env)

# Load default config/secrets.yml
secrets = Rails::Secrets.load(env: 'production')

# Check if active
Secvault.active? # => true/false
```

## Rails 7.1 Integration

For Rails 7.1 with existing secrets functionality:

```ruby
# config/initializers/secvault.rb
Secvault.setup_backward_compatibility_with_older_rails!
```

## ERB Templating

Supports full ERB templating for environment variables:

```yaml
production:
  api_key: <%= ENV['API_KEY'] %>
  pool_size: <%= ENV.fetch('DB_POOL', '5').to_i %>
  features:
    enabled: <%= ENV.fetch('FEATURES_ON', 'false') == 'true' %>
  hosts: <%= ENV.fetch('ALLOWED_HOSTS', 'localhost').split(',') %>
```

## Development Tools

Reload secrets in development:

```ruby
# Available after setup_multi_file!
reload_secrets!
Rails.application.reload_secrets!
```

## License

MIT
