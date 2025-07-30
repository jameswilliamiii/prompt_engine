# PromptEngine Encryption Configuration Guide

This guide explains how to set up Active Record Encryption for PromptEngine to securely store API keys in the Setting model.

## Overview

PromptEngine uses Rails' built-in Active Record Encryption to protect sensitive API keys stored in the database. This ensures that even if the database is compromised, the API keys remain encrypted and secure.

## Setup Instructions

### 1. Generate Encryption Keys

Run the following command to generate a random key set:

```bash
bin/rails db:encryption:init
```

This will output something like:

```yaml
active_record_encryption:
  primary_key: EGY8WhulUOXixybod7ZWwMIL68R9o5kC
  deterministic_key: aPA5XyALhf75NNnMzaspW7akTfZp0lPY
  key_derivation_salt: xEY0dt6TZcAMg52K7O84wYzkjvbA62Hz
```

### 2. Store Encryption Keys

You have two options for storing these encryption keys:

#### Option A: Rails Credentials (Recommended)

Add the generated keys to your Rails credentials:

```bash
rails credentials:edit
```

Then add:

```yaml
active_record_encryption:
  primary_key: YOUR_GENERATED_PRIMARY_KEY
  deterministic_key: YOUR_GENERATED_DETERMINISTIC_KEY
  key_derivation_salt: YOUR_GENERATED_KEY_DERIVATION_SALT
```

#### Option B: Environment Variables

Alternatively, you can configure these values using environment variables. Add to your `config/application.rb` or environment-specific config file:

```ruby
config.active_record.encryption.primary_key = ENV["ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY"]
config.active_record.encryption.deterministic_key = ENV["ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY"]
config.active_record.encryption.key_derivation_salt = ENV["ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT"]
```

Then set these environment variables in your deployment environment.

### 3. Verify Encryption is Working

Once configured, the Setting model will automatically encrypt the `encrypted_value` field when storing API keys. You can verify this is working:

```ruby
# In rails console
setting = PromptEngine::Setting.create!(
  key: 'test_key',
  encrypted_value: 'sensitive-api-key'
)

# The value is encrypted in the database
puts setting.encrypted_value # => "sensitive-api-key" (decrypted automatically)

# Check the raw database value to confirm encryption
raw_value = PromptEngine::Setting.connection.select_value(
  "SELECT encrypted_value FROM prompt_engine_settings WHERE id = #{setting.id}"
)
puts raw_value # => Should show encrypted gibberish
```

## Important Notes

1. **Keep Keys Secure**: Never commit encryption keys to version control. Use Rails credentials or environment variables.

2. **Key Rotation**: If you need to rotate keys, Rails provides built-in support. See the [Rails Encryption Guide](https://guides.rubyonrails.org/active_record_encryption.html#key-rotation).

3. **Backup Keys**: Make sure to backup your encryption keys securely. Without them, you won't be able to decrypt existing data.

4. **Environment Consistency**: Use the same encryption keys across all environments that share the same database (e.g., staging and production replicas).

## Host Application Integration

When integrating PromptEngine into a host Rails application, ensure the host application has Active Record Encryption configured before running migrations:

```ruby
# In host application's Gemfile
gem 'prompt_engine'

# Configure encryption keys first (see above)

# Then install and run migrations
bin/rails prompt_engine:install:migrations
bin/rails db:migrate
```

## Troubleshooting

### "Encryption key not found" Error

If you see this error, it means Active Record Encryption is not properly configured. Check that:
- The encryption keys are properly set in credentials or environment variables
- The Rails application can access the credentials file
- You've restarted the Rails server after adding the keys

### Existing Unencrypted Data

If you have existing unencrypted API keys in the database, you'll need to migrate them. Create a rake task:

```ruby
namespace :prompt_engine do
  desc "Encrypt existing API keys"
  task encrypt_existing_keys: :environment do
    PromptEngine::Setting.where(key: ['openai_api_key', 'anthropic_api_key']).find_each do |setting|
      # Force re-encryption by updating the value
      setting.update!(encrypted_value: setting.encrypted_value)
    end
  end
end
```

## Security Best Practices

1. **Principle of Least Privilege**: Only give decryption access to services that need it
2. **Audit Logging**: Log access to encrypted settings for security monitoring
3. **Regular Key Rotation**: Plan for periodic key rotation as part of security hygiene
4. **Secure Key Storage**: Use a key management service in production environments

## Further Reading

- [Rails Active Record Encryption Guide](https://guides.rubyonrails.org/active_record_encryption.html)
- [Rails Security Guide](https://guides.rubyonrails.org/security.html)