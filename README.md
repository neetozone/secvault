# Secvault

Restores the classic Rails `secrets.yml` functionality that was removed in Rails 7.2. Provides environment-specific secrets management with modern encryption support.

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
# 1. Create encrypted secrets.yml
rake secvault:setup

# 2. Edit secrets
rake secvault:edit

# 3. Add key to .gitignore
echo "/config/secrets.yml.key" >> .gitignore
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

**Production:** Set encryption key as environment variable:
```bash
export RAILS_SECRETS_KEY=your_encryption_key
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
rake secvault:setup    # Create encrypted secrets.yml and key
rake secvault:edit     # Edit encrypted secrets file
rake secvault:show     # Display decrypted content
```

## Security

⚠️ Never commit `config/secrets.yml.key` to version control  
✅ Use environment variables for production secrets  
✅ Set encryption key: `export RAILS_SECRETS_KEY=your_key`  

## License

MIT License - see [LICENSE](https://opensource.org/licenses/MIT)
