# Secvault

**Secvault** restores the classic Rails `secrets.yml` functionality that was removed in Rails 7.2, allowing you to manage encrypted secrets using the familiar YAML-based approach.

## Why Secvault?

Rails 7.2 removed the `secrets.yml` functionality completely in favor of credentials. However, many teams prefer the simplicity and familiarity of `secrets.yml` for managing environment-specific secrets. Secvault brings this functionality back with modern encryption support.

## Features

- 🔐 **Encrypted secrets.yml** - Uses Rails' built-in encryption system
- 🔑 **Key management** - Secure key generation and management
- 🌍 **Environment-specific** - Different secrets for development, test, and production
- 📝 **ERB support** - Use ERB templates in your secrets files
- 🛠️ **Rake tasks** - Easy management with built-in rake tasks
- 🚀 **Rails 7.2+ compatible** - Works seamlessly with modern Rails

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'secvault'
```

And then execute:

```bash
$ bundle install
```

### Rails Version Compatibility

- **Rails 7.2+**: Automatic setup, drop-in replacement for removed secrets functionality
- **Rails 7.1**: Manual setup required (see Rails 7.1 Integration section below)
- **Rails 8.0+**: Full compatibility

## Setup

### 1. Generate secrets file

Run the setup task to create your encrypted `secrets.yml`:

```bash
$ rake secvault:setup
```

This will:
- Generate `config/secrets.yml.key` (keep this secure!)
- Create an encrypted `config/secrets.yml` with default content
- Remind you to add the key file to `.gitignore`

Alternatively, use the Rails generator:

```bash
$ rails generate secvault:secrets
```

### 2. Add key to .gitignore

Ensure your encryption key is not committed to version control:

```bash
echo "/config/secrets.yml.key" >> .gitignore
```

## Usage

### Editing secrets

Edit your encrypted secrets file:

```bash
$ rake secvault:edit
```

This opens the decrypted file in your `$EDITOR`.

### Viewing secrets

View the decrypted content:

```bash
$ rake secvault:show
```

### Accessing secrets in your application

Secrets are automatically loaded into `Rails.application.secrets`:

```ruby
# In your Rails application
Rails.application.secrets.secret_key_base
Rails.application.secrets.api_key
Rails.application.secrets.database_password
```

### Example secrets.yml structure

```yaml
# config/secrets.yml (encrypted)
development:
  secret_key_base: your_development_secret
  api_key: dev_api_key
  database_password: dev_password

test:
  secret_key_base: your_test_secret
  api_key: test_api_key
  database_password: test_password

production:
  secret_key_base: <%= ENV['SECRET_KEY_BASE'] %>
  api_key: <%= ENV['API_KEY'] %>
  database_password: <%= ENV['DATABASE_PASSWORD'] %>
```

### Environment variable fallback

You can set the encryption key via environment variable:

```bash
export RAILS_SECRETS_KEY=your_encryption_key
```

## Production Deployment

### Option 1: Environment Variable

Set the encryption key as an environment variable:

```bash
export RAILS_SECRETS_KEY=your_encryption_key
```

### Option 2: Key File

Securely copy `config/secrets.yml.key` to your production server.

### Docker

For Docker deployments, you can pass the key as an environment variable:

```dockerfile
ENV RAILS_SECRETS_KEY=your_encryption_key
```

## Rake Tasks

| Task | Description |
|------|-------------|
| `rake secvault:setup` | Create encrypted secrets.yml and key |
| `rake secvault:edit` | Edit the encrypted secrets file |
| `rake secvault:show` | Display decrypted secrets content |

## Rails 7.1 Integration

For Rails 7.1 applications, Secvault provides a simple integration method to replace the native Rails::Secrets functionality and test Secvault before upgrading to Rails 7.2+.

### Quick Setup (Recommended)

Add this to `config/initializers/secvault.rb`:

```ruby
# config/initializers/secvault.rb
Secvault.setup_rails_71_integration!
```

That's it! This single line will:
- Override native Rails::Secrets with Secvault implementation
- Replace Rails.application.secrets with Secvault functionality
- Load secrets from config/secrets.yml automatically

### Manual Setup (Advanced)

If you prefer more control, you can set it up manually:

```ruby
# config/initializers/secvault.rb
module Rails
  remove_const(:Secrets) if defined?(Secrets)
  Secrets = Secvault::RailsSecrets
end

Rails.application.config.after_initialize do
  secrets_path = Rails.root.join("config/secrets.yml")
  
  if secrets_path.exist?
    loaded_secrets = Rails::Secrets.parse([secrets_path], env: Rails.env)
    secrets_object = ActiveSupport::OrderedOptions.new
    secrets_object.merge!(loaded_secrets)
    
    Rails.application.define_singleton_method(:secrets) do
      secrets_object
    end
  end
end
```

### Rails 7.1 Benefits

✅ **Test before upgrading**: Validate Secvault works with your secrets  
✅ **Zero code changes**: Existing Rails 7.1 code continues to work  
✅ **Smooth migration**: Gradual transition to Rails 7.2+  
✅ **Full compatibility**: All Rails.application.secrets functionality preserved  

### Example Rails 7.1 Usage

```ruby
# Works exactly like native Rails 7.1
Rails.application.secrets.api_key
Rails.application.secrets.oauth_settings[:google_client_id]

# Plus enhanced Secvault functionality
Rails::Secrets.parse_default(env: 'development')
Rails::Secrets.parse([custom_path], env: Rails.env)
```

## Migration from Rails < 7.2

If you're upgrading from an older Rails version that had `secrets.yml`:

1. Install secvault: `bundle add secvault`
2. Encrypt existing secrets: `rake secvault:setup`
3. Copy your existing secrets content using `rake secvault:edit`
4. Remove the old plain-text `config/secrets.yml`

## Security Best Practices

- ✅ **Never commit** `config/secrets.yml.key` to version control
- ✅ **Use environment variables** for production secrets when possible  
- ✅ **Rotate keys** periodically
- ✅ **Use strong, unique keys** for each environment
- ✅ **Limit access** to key files in production

## Troubleshooting

### Missing Key Error

```
Missing encryption key to decrypt secrets.yml
```

**Solution**: Ensure `config/secrets.yml.key` exists or set `RAILS_SECRETS_KEY` environment variable.

### Invalid Key Error

```
Invalid encryption key for secrets.yml
```

**Solution**: The key doesn't match the encrypted file. Verify you're using the correct key.

### File Not Found

```
Secrets file doesn't exist
```

**Solution**: Run `rake secvault:setup` to create the secrets file.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/unnitallman/secvault.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Secvault project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/secvault/blob/main/CODE_OF_CONDUCT.md).
