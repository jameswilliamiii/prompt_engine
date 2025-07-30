# PromptEngine

A powerful Rails engine for managing AI prompts with version control, A/B testing, and seamless LLM
integration. PromptEngine provides a centralized admin interface where teams can create, version,
test, and optimize their AI prompts without deploying code changes.

[![Made with ❤️ by Avi.nyc](https://img.shields.io/badge/Made%20with%20%E2%9D%A4%EF%B8%8F%20by-Avi.nyc-ff69b4)](https://avi.nyc)
[![Sponsored by Innovent Capital](https://img.shields.io/badge/Sponsored%20by-Innovent%20Capital-blue)](https://innoventcapital.com)

## Why PromptEngine?

- **Version Control**: Track every change to your prompts with automatic versioning
- **A/B Testing**: Test different prompt variations with built-in evaluation tools
- **No Deploy Required**: Update prompts through the admin UI without code changes
- **LLM Agnostic**: Works with OpenAI, Anthropic, and other providers
- **Type Safety**: Automatic parameter detection and validation
- **Team Collaboration**: Centralized prompt management for your entire team
- **Production Ready**: Battle-tested with secure API key storage

## Features

- 🎯 **Smart Prompt Management**: Create and organize prompts with slug-based identification
- 📝 **Version Control**: Automatic versioning with one-click rollback
- 🔍 **Variable Detection**: Auto-detects `{{variables}}` and creates typed parameters
- 🧪 **Playground**: Test prompts with real AI providers before deploying
- 📊 **Evaluation Suite**: Create test cases and measure prompt performance
- 🔐 **Secure**: Encrypted API key storage using Rails encryption
- 🚀 **Modern API**: Object-oriented design with direct LLM integration

## Installation

Add this line to your application's Gemfile:

```ruby
gem "prompt_engine"
```

```sh
bundle add "prompt_engine"
```

And then execute:

```bash
$ bundle

# IMPORTANT: You must install migrations before running db:migrate
$ rails prompt_engine:install:migrations
$ rails db:migrate
$ rails prompt_engine:seed  # Optional: adds sample prompts
```

**Note**: PromptEngine migrations are NOT automatically loaded. You must explicitly run `rails prompt_engine:install:migrations` before running `rails db:migrate`.

For migration handling details, see [docs/MIGRATIONS.md](docs/MIGRATIONS.md).

## Setup

### 1. Configure Encryption

PromptEngine uses Rails encryption to secure API keys. For detailed setup instructions, see
[docs/ENCRYPTION_SETUP.md](docs/ENCRYPTION_SETUP.md).

**Quick start for development:**

```ruby
# config/environments/development.rb
config.active_record.encryption.primary_key = 'development' * 4
config.active_record.encryption.deterministic_key = 'development' * 4
config.active_record.encryption.key_derivation_salt = 'development' * 4
```

For production, use `rails db:encryption:init` to generate secure keys.

### 2. Configure API Keys

Add your AI provider API keys to Rails credentials. See
[docs/API_CREDENTIALS.md](docs/API_CREDENTIALS.md) for complete configuration options.

```bash
rails credentials:edit
```

```yaml
openai:
  api_key: sk-your-openai-api-key
anthropic:
  api_key: sk-ant-your-anthropic-api-key
```

### 3. Mount the Engine

In your `config/routes.rb`:

```ruby
Rails.application.routes.draw do
  mount PromptEngine::Engine => "/prompt_engine"
  # your other routes...
end
```

### 4. Authentication (Recommended for Production)

PromptEngine provides flexible authentication options to secure your admin interface. Since prompt templates may contain sensitive business logic, we strongly recommend configuring authentication for production environments.

#### Quick Start

Choose one of these authentication methods based on your needs:

##### Option 1: Route-level Authentication (Devise)

```ruby
# config/routes.rb
authenticate :user, ->(u) { u.admin? } do
  mount PromptEngine::Engine => "/prompt_engine"
end
```

##### Option 2: Basic Authentication

```ruby
# config/initializers/prompt_engine.rb
PromptEngine::Engine.middleware.use(Rack::Auth::Basic) do |username, password|
  ActiveSupport::SecurityUtils.secure_compare(
    Rails.application.credentials.prompt_engine_username, username
  ) & ActiveSupport::SecurityUtils.secure_compare(
    Rails.application.credentials.prompt_engine_password, password
  )
end
```

##### Option 3: Custom Authentication

```ruby
# config/initializers/prompt_engine.rb
ActiveSupport.on_load(:prompt_engine_application_controller) do
  before_action :authenticate_admin!
  
  private
  
  def authenticate_admin!
    redirect_to main_app.root_path unless current_user&.admin?
  end
  
  def current_user
    # Your app's current user method
    main_app.current_user
  end
end
```

#### Rails 8 Authentication

If using Rails 8's built-in authentication generator:

```ruby
# config/initializers/prompt_engine.rb
ActiveSupport.on_load(:prompt_engine_application_controller) do
  include Authentication # Rails 8's authentication concern
  before_action :require_authentication
end
```

#### Security Best Practices

1. **Always enable authentication in production**
2. **Use strong, unique passwords**
3. **Store credentials securely** (Rails credentials or environment variables)
4. **Use HTTPS** to encrypt credentials in transit
5. **Implement rate limiting** to prevent brute force attacks

For detailed authentication documentation and more examples, see [AUTH.md](AUTH.md)

## Usage

For detailed usage instructions and examples, see [docs/USAGE.md](docs/USAGE.md).

### Admin Interface

Visit `/prompt_engine` in your browser to access the admin interface where you can:

- Create and manage prompts
- Test prompts in the playground
- View version history
- Create evaluation sets
- Monitor prompt performance

### In Your Application

```ruby
# Render a prompt with variables (defaults to active prompts only)
rendered = PromptEngine.render("customer-support",
  { customer_name: "John", issue: "Can't login to my account" }
)

# Access rendered content
rendered.content         # => "Hello John, I understand you're having trouble..."
rendered.system_message  # => "You are a helpful customer support agent..."
rendered.model          # => "gpt-4"
rendered.temperature    # => 0.7

# Access parameter values - see docs/VARIABLE_ACCESS.md for details
rendered.parameters      # => {"customer_name" => "John", "issue" => "Can't login..."}
rendered.parameter(:customer_name)  # => "John"

# Direct integration with OpenAI
client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])
response = rendered.execute_with(client)

# Or with Anthropic
client = Anthropic::Client.new(access_token: ENV["ANTHROPIC_API_KEY"])
response = rendered.execute_with(client)

# Override model settings at runtime
rendered = PromptEngine.render("email-writer",
  { subject: "Welcome to our platform" },
  options: { model: "gpt-4-turbo", temperature: 0.9 }
)

# Load a specific version
rendered = PromptEngine.render("onboarding-email",
  { user_name: "Sarah" },
  options: { version: 3 }
)

# Render prompts with different statuses (defaults to 'active')
# Useful for testing drafts or accessing archived prompts
rendered = PromptEngine.render("new-feature",
  { feature_name: "AI Assistant" },
  options: { status: "draft" }  # Can be 'draft', 'active', or 'archived'
)
```

For complete parameter access documentation, see [docs/VARIABLE_ACCESS.md](docs/VARIABLE_ACCESS.md).
For status filtering details, see [docs/STATUS_FILTERING.md](docs/STATUS_FILTERING.md).

## How It Works

1. **Create Prompts**: Use the admin UI to create prompts with `{{variables}}`
2. **Auto-Detection**: PromptEngine automatically detects variables and creates parameters
3. **Version Control**: Every save creates a new version automatically
4. **Test & Deploy**: Test in the playground, then use in your application
5. **Monitor**: Track usage and performance through the dashboard

## API Documentation

### PromptEngine.render(slug, variables = {}, options: {})

Renders a prompt template with the given variables.

**Parameters:**

- `slug` (String): The unique identifier for the prompt
- `variables` (Hash): Variables to interpolate in the prompt (optional positional argument)
- `options:` (Hash): Rendering options (optional keyword argument)
  - `status`: The status to filter by (defaults to 'active')
  - `model`: Override the default model
  - `temperature`: Override the default temperature
  - `max_tokens`: Override the default max tokens
  - `version`: Load a specific version number

**Returns:** `PromptEngine::RenderedPrompt` instance

### RenderedPrompt Methods

- `content`: The rendered prompt content
- `system_message`: The system message (if any)
- `model`: The AI model to use
- `temperature`: The temperature setting
- `max_tokens`: The max tokens setting
- `to_openai_params`: Convert to OpenAI API format
- `to_ruby_llm_params`: Convert to RubyLLM/Anthropic format
- `execute_with(client)`: Execute with an LLM client

## Contributing

We welcome contributions! Here's how you can help:

### Development Setup

1. Fork the repository
2. Clone your fork:

   ```bash
   git clone https://github.com/YOUR_USERNAME/prompt_engine.git
   cd prompt_engine
   ```

3. Install dependencies:

   ```bash
   bundle install
   ```

4. Set up the test database:

   ```bash
   cd spec/dummy
   rails db:create db:migrate db:seed
   cd ../..
   ```

5. Run the tests:

   ```bash
   bundle exec rspec
   ```

6. Start the development server:
   ```bash
   cd spec/dummy && rails server
   ```

### Making Changes

1. Create a feature branch:

   ```bash
   git checkout -b feature/your-feature-name
   ```

2. Make your changes and ensure tests pass:

   ```bash
   bundle exec rspec
   bundle exec rubocop
   ```

3. Commit your changes:

   ```bash
   git commit -m "Add your feature"
   ```

4. Push to your fork:

   ```bash
   git push origin feature/your-feature-name
   ```

5. Create a Pull Request

### Guidelines

- Write tests for new features
- Follow Rails best practices
- Use conventional commit messages
- Update documentation as needed
- Be respectful in discussions

## Architecture

PromptEngine follows Rails engine conventions with a modular architecture:

- **Models**: Prompt, PromptVersion, Parameter, EvalSet, TestCase
- **Services**: VariableDetector, PlaygroundExecutor, PromptRenderer
- **Admin UI**: Built with Hotwire, Stimulus, and Turbo
- **API**: Object-oriented design with RenderedPrompt instances

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for detailed technical documentation.

## Roadmap

- [ ] Multi-language prompt support
- [ ] Prompt templates marketplace
- [ ] Advanced A/B testing analytics
- [ ] Webhook integrations
- [ ] Prompt chaining
- [ ] Cost tracking and optimization
- [ ] Team collaboration features

## Sponsors

- [Innovent Capital](https://innoventcapital.com) - _Pioneering AI innovation in financial services_

## License

The gem is available as open source under the terms of the
[MIT License](https://opensource.org/licenses/MIT).

## Documentation

- 📖 [Architecture Overview](docs/ARCHITECTURE.md) - Technical architecture and design decisions
- 🔐 [Authentication Guide](docs/AUTHENTICATION.md) - Securing your PromptEngine installation
- 🔑 [API Credentials Setup](docs/API_CREDENTIALS.md) - Configuring AI provider API keys
- 🔒 [Encryption Setup](docs/ENCRYPTION_SETUP.md) - Setting up Rails encryption for secure storage
- 📦 [Migration Guide](docs/MIGRATIONS.md) - Handling database migrations
- 📝 [Usage Guide](docs/USAGE.md) - Complete usage examples and best practices
- 🔤 [Variable Access](docs/VARIABLE_ACCESS.md) - Working with parameters in rendered prompts
- 🎯 [Method Signature](docs/METHOD_SIGNATURE.md) - Understanding the render method's positional arguments
- 🏷️ [Status Filtering](docs/STATUS_FILTERING.md) - Working with draft, active, and archived prompts
- 🤖 [LLM Integration](docs/PROMPT-USAGE.md) - Using rendered prompts with OpenAI, Anthropic, RubyLLM, and custom clients
- 📋 [Product Specification](docs/SPEC.md) - Complete product vision and roadmap

## Support

- 📖 [Documentation](docs/)
- 🐛 [Issue Tracker](https://github.com/aviflombaum/prompt_engine/issues)
- 💬 [Discussions](https://github.com/aviflombaum/prompt_engine/discussions)
- 📧 [Email Support](mailto:ruby@avi.nyc)

---

Built with ❤️ by [Avi.nyc](https://avi.nyc)
