# Secvault

Restores the classic Rails `secrets.yml` functionality that was removed in Rails 7.2. Uses simple, plain YAML files for environment-specific secrets management.

**Rails Version Support:**
- **Rails 7.1**: Manual setup (see Rails 7.1 Integration below)
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
# 1. Create secrets.yml with rake task
rake secvault:setup

# 2. Edit secrets
rake secvault:edit
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

## Rails 7.1 Integration

Test Secvault in Rails 7.1 before upgrading to 7.2+:

```ruby
# config/initializers/secvault.rb
Secvault.setup_rails_71_integration!
```

This replaces Rails.application.secrets with Secvault functionality. Your existing Rails 7.1 code works unchanged:

```ruby
Rails.application.secrets.api_key          # ✅ Works
Rails.application.secrets.oauth_settings   # ✅ Works
Rails::Secrets.parse_default               # ✅ Enhanced functionality
```

## Available Commands

```bash
rake secvault:setup    # Create plain secrets.yml file
rake secvault:edit     # Edit secrets.yml file
rake secvault:show     # Display secrets.yml content
```

## Security

⚠️ Never commit production secrets to version control  
✅ Use environment variables for production secrets with ERB syntax: `<%= ENV['SECRET'] %>`  
✅ Add `config/secrets.yml` to `.gitignore` if it contains sensitive data

## License

MIT License - see [LICENSE](https://opensource.org/licenses/MIT)
