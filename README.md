# PromptEngine

A Rails engine for managing AI prompts with version control and secure API key storage.

## Installation
Add this line to your application's Gemfile:

```ruby
gem "prompt_engine"
```

And then execute:
```bash
$ bundle
$ rails prompt_engine:install:migrations
$ rails db:migrate
```

## Setup

### Configure Encryption

PromptEngine uses Rails encryption to secure API keys. Add to your environment files:

```ruby
# config/environments/development.rb
config.active_record.encryption.primary_key = 'development' * 4
config.active_record.encryption.deterministic_key = 'development' * 4
config.active_record.encryption.key_derivation_salt = 'development' * 4
```

For production, use `rails db:encryption:init` to generate secure keys.

### Configure API Keys

PromptEngine requires API keys for AI providers. See [API Credentials Setup](docs/API_CREDENTIALS.md) for detailed configuration instructions.

Quick setup:
```bash
rails credentials:edit
```

Add your API keys:
```yaml
openai:
  api_key: sk-your-openai-api-key
anthropic:
  api_key: sk-ant-your-anthropic-api-key
```

### Mount the Engine

In your `config/routes.rb`:

```ruby
mount PromptEngine::Engine => "/prompt_engine"
```

## Usage

Visit `/prompt_engine` to access the admin interface.

## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
