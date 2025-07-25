# API Credentials Setup

## Overview

ActivePrompt integrates with multiple AI providers including OpenAI and Anthropic. This guide explains how to configure API keys for these services.

## Rails Credentials Configuration

ActivePrompt uses Rails encrypted credentials to securely store API keys. 

### Setting up API Keys

1. **Edit your credentials file:**

```bash
# For development
rails credentials:edit --environment development

# For production
rails credentials:edit --environment production
```

2. **Add your API keys in the following format:**

```yaml
# OpenAI Configuration
openai:
  api_key: sk-your-openai-api-key-here
  # For OpenAI Evals API (optional)
  evals_enabled: true  # Set to true if you have access to OpenAI Evals API

# Anthropic Configuration
anthropic:
  api_key: sk-ant-your-anthropic-api-key-here

# Optional: Default model settings
active_prompt:
  default_model: gpt-4  # or claude-3-sonnet
  default_temperature: 0.7
  default_max_tokens: 1000
```

### Environment-Specific Configuration

You can have different API keys for different environments:

```yaml
# config/credentials/development.yml.enc
openai:
  api_key: sk-dev-key-here

# config/credentials/production.yml.enc  
openai:
  api_key: sk-prod-key-here
```

## API Key Requirements

### OpenAI
- **Basic Usage**: Standard OpenAI API key with access to chat completions
- **Evaluations**: Requires access to OpenAI Evals API (not available on all accounts)
- **Get your key**: https://platform.openai.com/api-keys

### Anthropic
- **Basic Usage**: Standard Anthropic API key
- **Get your key**: https://console.anthropic.com/settings/keys

## Testing Your Configuration

You can verify your API keys are properly configured by running:

```ruby
# Rails console
rails c

# Test OpenAI
ActivePrompt::PlaygroundExecutor.new(
  prompt_version: ActivePrompt::PromptVersion.first,
  input_variables: { topic: "test" }
).execute

# Check if credentials are loaded
Rails.application.credentials.openai[:api_key]
# => Should return your API key (not nil)
```

## Security Best Practices

1. **Never commit API keys to version control**
   - Rails credentials are encrypted by default
   - Keep your master.key secure and never commit it

2. **Use environment-specific keys**
   - Different keys for development, staging, and production
   - Helps track usage and prevents development affecting production quotas

3. **Rotate keys regularly**
   - Update credentials when team members leave
   - Rotate after any suspected compromise

4. **Set rate limits**
   - Configure rate limits in your AI provider dashboards
   - Monitor usage to detect anomalies

## Troubleshooting

### "API key not found" errors
1. Ensure credentials are saved: `rails credentials:edit`
2. Check the key path: `Rails.application.credentials.openai[:api_key]`
3. Verify environment: Are you editing the right credentials file?

### "Invalid API key" errors
1. Verify the key is correct and active in your provider's dashboard
2. Check for extra whitespace or characters
3. Ensure the key has necessary permissions

### OpenAI Evals API Access
- Not all OpenAI accounts have access to the Evals API
- Contact OpenAI support to request access if needed
- The eval feature will fail gracefully if access is not available

## Example Usage in Controllers

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  private
  
  def openai_api_key
    Rails.application.credentials.openai[:api_key]
  end
  
  def anthropic_api_key
    Rails.application.credentials.anthropic[:api_key]
  end
end
```