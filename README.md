# Secvault

Restores Rails `secrets.yml` functionality. Simple YAML files for environment-specific secrets management.

[![Gem Version](https://img.shields.io/gem/v/secvault.svg)](https://rubygems.org/gems/secvault)

## Installation

```ruby
gem 'secvault'
```

## Usage

**1. Add to initializer:**
```ruby
# config/initializers/secvault.rb
Secvault.start!
```

**2. Create secrets file:**
```yaml
# config/secrets.yml
shared:
  app_name: "MyApp"

development:
  secret_key_base: "dev_secret"
  api_key: "dev_key"

production:
  secret_key_base: <%= ENV['SECRET_KEY_BASE'] %>
  api_key: <%= ENV['API_KEY'] %>
```

**3. Use in your app:**
```ruby
Secvault.secrets.api_key
Secvault.secrets.app_name
```

## Options

```ruby
Secvault.start!(
  files: ['config/secrets.yml'],           # Default
  integrate_with_rails: false,             # Default: false
  set_secret_key_base: true,              # Default: true
  hot_reload: true,                       # Default: true in development
  logger: true                            # Default: true except production
)
```

**Primary access (default):**
```ruby
Secvault.secrets.api_key
Secvault.secrets.app_name
```

**Rails integration (optional):**
```ruby
# Enable Rails.application.secrets access
Secvault.start!(integrate_with_rails: true)

# Then use either:
Secvault.secrets.api_key          # Direct access
Rails.application.secrets.api_key # Rails integration
```

**Examples:**
```ruby
# Multiple files
Secvault.start!(files: ['secrets.yml', 'local.yml'])
```


## Advanced

**ERB templating:**
```yaml
production:
  api_key: <%= ENV['API_KEY'] %>
  pool_size: <%= ENV.fetch('DB_POOL', '5').to_i %>
  hosts: <%= ENV.fetch('ALLOWED_HOSTS', 'localhost').split(',') %>
```

**Shared sections:**
```yaml
shared:
  app_name: "MyApp"
  features:
    analytics: true

development:
  secret_key_base: "dev_secret"
  features:
    debug: true  # Merges with shared.features
```

**Hot reload (development):**
```ruby
# Enabled by default in development
reload_secrets!
```
**Manual API:**
```ruby
# Parse files directly
Rails::Secrets.parse(['secrets.yml'], env: 'production')

# Check status
Secvault.active?           # => true/false
Secvault.rails_integrated? # => true/false
```


## License

MIT
