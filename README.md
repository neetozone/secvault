# Secvault

Restores the classic Rails `secrets.yml` functionality that was removed in Rails 7.2. Uses simple, plain YAML files for environment-specific secrets management.

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

**Example secrets.yml:**
```yaml
development:
  api_key: dev_key
  database_password: dev_password

production:
  api_key: <%= ENV['API_KEY'] %>
  database_password: <%= ENV['DATABASE_PASSWORD'] %>
```

**Production:** Use environment variables in your YAML:
```yaml
production:
  api_key: <%= ENV['API_KEY'] %>
```

## Advanced Usage

**Multiple secrets files (merged in order):**
```ruby
# Parse multiple files - later files override earlier ones
secrets = Rails::Secrets.parse([
  'config/secrets.yml',
  'config/secrets.local.yml',
  'config/secrets.production.yml'
], env: Rails.env)
```

**Load specific environment:**
```ruby
# Load production secrets in any environment
production_secrets = Rails::Secrets.load(env: 'production')

# Load development secrets
dev_secrets = Rails::Secrets.load(env: 'development')
```

**Custom files:**
```ruby
# Parse a custom secrets file
custom_secrets = Rails::Secrets.parse(['config/custom.yml'], env: Rails.env)

# Parse from different paths
all_secrets = Rails::Secrets.parse([
  Rails.root.join('config', 'secrets.yml'),
  Rails.root.join('config', 'deploy', 'secrets.yml')
], env: Rails.env)
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


## Security

⚠️ Never commit production secrets to version control  
✅ Use environment variables for production secrets with ERB syntax: `<%= ENV['SECRET'] %>`  
✅ Add `config/secrets.yml` to `.gitignore` if it contains sensitive data

## License

MIT License - see [LICENSE](https://opensource.org/licenses/MIT)
