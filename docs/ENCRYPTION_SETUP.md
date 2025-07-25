# Active Record Encryption Setup for PromptEngine

PromptEngine uses Rails' built-in Active Record encryption to automatically encrypt API keys. No
manual encryption code is needed.

## Development Setup

For development, add to `spec/dummy/config/environments/development.rb`:

```ruby
config.active_record.encryption.primary_key = 'development' * 4  # 32 bytes
config.active_record.encryption.deterministic_key = 'development' * 4  # 32 bytes
config.active_record.encryption.key_derivation_salt = 'development' * 4  # 32 bytes
```

## Setup for Production

### 1. Generate Encryption Keys

In your Rails application:

```bash
bin/rails db:encryption:init
```

### 2. Add Keys to Credentials

```bash
EDITOR="code --wait" bin/rails credentials:edit
```

Add the generated keys:

```yaml
active_record_encryption:
  primary_key: [generated_key]
  deterministic_key: [generated_key]
  key_derivation_salt: [generated_key]
```

That's it! Rails automatically handles:

- Encrypting data before saving to database
- Decrypting data when reading from database
- All the cryptographic complexity

## How It Works

The Setting model simply declares which attributes to encrypt:

```ruby
class Setting < ApplicationRecord
  encrypts :openai_api_key
  encrypts :anthropic_api_key
end
```

When you save a setting:

```ruby
setting = Setting.instance
setting.openai_api_key = "sk-abc123"  # Rails encrypts this automatically
setting.save
```

When you read it back:

```ruby
setting.openai_api_key  # Rails decrypts automatically, returns "sk-abc123"
```

## Testing

For test environments, add to `config/environments/test.rb`:

```ruby
config.active_record.encryption.primary_key = 'test' * 8
config.active_record.encryption.deterministic_key = 'test' * 8
config.active_record.encryption.key_derivation_salt = 'test' * 8
```

## Troubleshooting

If you see "Missing Active Record encryption credential", ensure:

1. You've run `rails db:encryption:init`
2. Added keys to credentials
3. Restarted your Rails server

That's all there is to it!
