# Secvault

Rails secrets.yml functionality for Rails 7.2+. Secvault restores the classic Rails secrets.yml functionality that was removed in Rails 7.2, allowing you to manage secrets using the familiar YAML-based approach.

[![Gem Version](https://img.shields.io/gem/v/secvault.svg)](https://rubygems.org/gems/secvault)
[![CI](https://github.com/unnitallman/secvault/actions/workflows/ci.yml/badge.svg)](https://github.com/unnitallman/secvault/actions/workflows/ci.yml)

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
defaults: &defaults
  app_name: "MyApp"

development:
  <<: *defaults
  secret_key_base: "dev_secret"
  api_key: "dev_key"

production:
  <<: *defaults
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
  files: ['config/secrets.yml'],     # Files to load (later files override earlier ones)
  integrate_with_rails: false,       # Add Rails.application.secrets
  set_secret_key_base: true,         # Auto-set Rails.application.config.secret_key_base from secrets
  hot_reload: true,                  # Auto-reload in development
  logger: true                       # Log loading activity
)
```

**Multiple files:**
```ruby
# Later files override earlier ones
Secvault.start!(files: ['secrets.yml', 'local.yml'])
```

**Rails integration:**
```ruby
Secvault.start!(integrate_with_rails: true)
Rails.application.secrets.api_key  # Now available
```

**Secret key base:**
```ruby
# If your secrets.yml has secret_key_base, it's automatically set
# This replaces the need for Rails.application.config.secret_key_base
Secvault.start!(set_secret_key_base: true)  # Default behavior
```


## Advanced

**ERB templating:**
```yaml
production:
  api_key: <%= ENV['API_KEY'] %>
  pool_size: <%= ENV.fetch('DB_POOL', '5').to_i %>
```

**YAML anchors for sharing:**
```yaml
defaults: &defaults
  app_name: "MyApp"
  timeout: 30

development:
  <<: *defaults
  debug: true

production:
  <<: *defaults
  timeout: 10  # Override specific values
```

**Development helpers:**
```ruby
reload_secrets!            # Reload files
Secvault.active?           # Check status
```


## License

MIT
