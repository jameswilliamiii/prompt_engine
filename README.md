# ActivePrompt

A Rails engine for managing AI prompts with version control and secure API key storage.

## Installation
Add this line to your application's Gemfile:

```ruby
gem "active_prompt"
```

And then execute:
```bash
$ bundle
$ rails active_prompt:install:migrations
$ rails db:migrate
```

## Setup

### Configure Encryption

ActivePrompt uses Rails encryption to secure API keys. Add to your environment files:

```ruby
# config/environments/development.rb
config.active_record.encryption.primary_key = 'development' * 4
config.active_record.encryption.deterministic_key = 'development' * 4
config.active_record.encryption.key_derivation_salt = 'development' * 4
```

For production, use `rails db:encryption:init` to generate secure keys.

### Mount the Engine

In your `config/routes.rb`:

```ruby
mount ActivePrompt::Engine => "/active_prompt"
```

## Usage

Visit `/active_prompt` to access the admin interface.

## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
