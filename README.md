# Secvault

Simple YAML secrets management for Rails. Uses standard YAML anchors for sharing configuration.

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
  files: ['config/secrets.yml'],     # Files to load (later files deep-merge over earlier ones)
  integrate_with_rails: false,       # Add Rails.application.secrets
  set_secret_key_base: true,         # Set Rails secret_key_base
  hot_reload: true,                  # Auto-reload in development
  logger: true                       # Log loading activity
)
```

**Multiple files:**
```ruby
# Later files deep-merge over earlier ones
Secvault.start!(files: ['secrets.yml', 'local.yml'])
```

**Rails integration:**
```ruby
Secvault.start!(integrate_with_rails: true)
Rails.application.secrets.api_key  # Now available
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
