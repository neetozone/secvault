# Secvault API

Secvault provides separate control over secrets loading and Rails integration.

## Core Methods

### `Secvault.start!(files: [])`

Loads secrets from YAML files. Returns `true`/`false`.

- **Default**: Uses `config/secrets.yml` if `files` is empty
- **Access**: Secrets available via `Secvault.secrets`
- **Non-invasive**: Does not modify `Rails.application.secrets`

### `Secvault.integrate_with_rails!`

Replaces `Rails.application.secrets` with Secvault's loaded secrets. Returns `true`/`false`.

### `Secvault.secrets`

Access to loaded secrets as `ActiveSupport::OrderedOptions`.

### Status Methods

- `Secvault.active?` - Returns `true` if secrets have been loaded
- `Secvault.rails_integrated?` - Returns `true` if Rails integration is active

## Usage

### Standalone

```ruby
# Load secrets independently
Secvault.start!
api_key = Secvault.secrets.api_key
```

### With Rails Integration

```ruby
# Load and integrate with Rails
Secvault.start!
Secvault.integrate_with_rails!
api_key = Rails.application.secrets.api_key
```

### Multiple Files

```ruby
# Files are deep-merged in order
Secvault.start!(files: [
  'config/shared_secrets.yml',
  'config/secrets.yml'
])
```

### Error Handling

```ruby
if Secvault.start!(files: ['config/secrets.yml'])
  if Secvault.integrate_with_rails!
    # Both operations successful
  end
end
```
