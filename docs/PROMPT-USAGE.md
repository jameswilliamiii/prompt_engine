# Using Rendered Prompts with LLM Providers

This guide covers all the ways you can use PromptEngine's rendered prompts with various LLM provider gems and custom clients in your Rails application.

## Table of Contents

- [Basic Usage](#basic-usage)
- [Accessing Rendered Prompt Data](#accessing-rendered-prompt-data)
- [Integration Methods](#integration-methods)
  - [Automatic Integration with execute_with](#automatic-integration-with-execute_with)
  - [OpenAI Gem Integration](#openai-gem-integration)
  - [RubyLLM Integration](#rubyllm-integration)
  - [Anthropic Integration](#anthropic-integration)
- [Manual Integration Patterns](#manual-integration-patterns)
  - [Using the Messages Array](#using-the-messages-array)
  - [Using Hash Representation](#using-hash-representation)
  - [Custom Client Integration](#custom-client-integration)
- [Advanced Usage](#advanced-usage)
  - [Overriding Options at Execution Time](#overriding-options-at-execution-time)
  - [Working with Different Model Types](#working-with-different-model-types)
  - [Handling Responses](#handling-responses)

## Basic Usage

First, render a prompt with your variables:

```ruby
rendered = PromptEngine.render("customer-support",
  { customer_name: "Alice", issue: "Password reset" }
)
```

The `rendered` object is a `PromptEngine::RenderedPrompt` instance that provides multiple ways to integrate with LLM providers.

## Accessing Rendered Prompt Data

The rendered prompt provides accessors for all the data you might need:

```ruby
# Core content
rendered.content         # => "Help Alice with Password reset"
rendered.system_message  # => "You are a helpful support agent"

# Model configuration
rendered.model           # => "gpt-4"
rendered.temperature     # => 0.7
rendered.max_tokens      # => 1000

# Metadata
rendered.status          # => "active"
rendered.version         # => 3

# Parameters used
rendered.parameters      # => {"customer_name" => "Alice", "issue" => "Password reset"}
rendered.parameter(:customer_name)  # => "Alice"

# Options passed during rendering
rendered.options         # => {model: "gpt-4", temperature: 0.7}
```

## Integration Methods

### Automatic Integration with execute_with

The simplest way to execute a rendered prompt is using the `execute_with` method, which automatically detects the client type and formats the request appropriately:

```ruby
# OpenAI
client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])
response = rendered.execute_with(client)

# Anthropic
client = Anthropic::Client.new(access_token: ENV["ANTHROPIC_API_KEY"])
response = rendered.execute_with(client)

# RubyLLM
client = RubyLLM::ChatModels::OpenAI.new(api_key: ENV["OPENAI_API_KEY"])
response = rendered.execute_with(client)
```

You can also pass additional options:

```ruby
response = rendered.execute_with(client, 
  stream: true,
  tools: [...],
  response_format: { type: "json_object" }
)
```

### OpenAI Gem Integration

For direct OpenAI gem usage, use the `to_openai_params` method:

```ruby
require "openai"

client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])

# Get formatted parameters
params = rendered.to_openai_params

# Make the API call
response = client.chat(parameters: params)

# Access the response
puts response.dig("choices", 0, "message", "content")
```

Adding additional OpenAI-specific options:

```ruby
# Add tools, functions, or other OpenAI-specific parameters
params = rendered.to_openai_params(
  tools: [
    {
      type: "function",
      function: {
        name: "get_weather",
        description: "Get the current weather",
        parameters: {
          type: "object",
          properties: {
            location: { type: "string" }
          }
        }
      }
    }
  ],
  response_format: { type: "json_object" }
)

response = client.chat(parameters: params)
```

### RubyLLM Integration

RubyLLM provides a unified interface for multiple LLM providers:

```ruby
require "ruby_llm"

# Configure RubyLLM
RubyLLM.configure do |config|
  config.openai_api_key = ENV["OPENAI_API_KEY"]
  config.anthropic_api_key = ENV["ANTHROPIC_API_KEY"]
end

# Create a chat model
chat = RubyLLM.chat(provider: "openai", model: rendered.model)

# Get formatted parameters
params = rendered.to_ruby_llm_params

# Execute the prompt
response = chat.messages(params[:messages])
              .with_temperature(params[:temperature])
              .with_max_tokens(params[:max_tokens])
              .ask

# Or more concisely
response = chat.ask(params[:messages][-1][:content],
  instructions: params[:messages][0][:content],
  temperature: params[:temperature],
  max_tokens: params[:max_tokens]
)
```

Using RubyLLM with different providers:

```ruby
# Anthropic via RubyLLM
anthropic_chat = RubyLLM.chat(provider: "anthropic", model: "claude-3-opus")
response = anthropic_chat.messages(rendered.messages)
                        .with_temperature(rendered.temperature)
                        .ask

# OpenAI via RubyLLM
openai_chat = RubyLLM.chat(provider: "openai", model: rendered.model)
response = openai_chat.messages(rendered.messages)
                     .with_temperature(rendered.temperature)
                     .ask
```

### Anthropic Integration

For direct Anthropic usage:

```ruby
require "anthropic"

client = Anthropic::Client.new(access_token: ENV["ANTHROPIC_API_KEY"])

# Get formatted parameters
params = rendered.to_ruby_llm_params

# Anthropic expects a specific format
response = client.messages(
  model: params[:model] || "claude-3-opus",
  messages: params[:messages],
  max_tokens: params[:max_tokens] || 1000,
  temperature: params[:temperature]
)

puts response.dig("content", 0, "text")
```

## Manual Integration Patterns

### Using the Messages Array

The `messages` method returns a properly formatted array for chat models:

```ruby
messages = rendered.messages
# => [
#      { role: "system", content: "You are a helpful support agent" },
#      { role: "user", content: "Help Alice with Password reset" }
#    ]

# Use with any client that expects messages format
response = custom_client.complete(
  messages: messages,
  model: rendered.model,
  temperature: rendered.temperature
)
```

### Using Hash Representation

The `to_h` method provides complete access to all data:

```ruby
data = rendered.to_h
# => {
#      content: "Help Alice with Password reset",
#      system_message: "You are a helpful support agent",
#      model: "gpt-4",
#      temperature: 0.7,
#      max_tokens: 1000,
#      messages: [...],
#      options: {...},
#      status: "active",
#      version: 3,
#      parameters: {"customer_name" => "Alice", "issue" => "Password reset"}
#    }

# Use with custom API clients
response = CustomLLMClient.generate(
  prompt: data[:content],
  system: data[:system_message],
  model: data[:model],
  config: {
    temperature: data[:temperature],
    max_tokens: data[:max_tokens]
  }
)
```

### Custom Client Integration

For clients with unique interfaces, access individual components:

```ruby
# For a client that separates system and user prompts
response = ProprietaryLLM.complete(
  system_prompt: rendered.system_message,
  user_prompt: rendered.content,
  model_name: rendered.model,
  creativity: rendered.temperature,
  token_limit: rendered.max_tokens
)

# For a client that uses a single prompt
combined_prompt = if rendered.system_message.present?
  "#{rendered.system_message}\n\n#{rendered.content}"
else
  rendered.content
end

response = SimpleLLM.generate(
  text: combined_prompt,
  settings: {
    model: rendered.model,
    temp: rendered.temperature
  }
)
```

## Advanced Usage

### Overriding Options at Execution Time

You can override prompt settings when executing:

```ruby
# Render with default settings
rendered = PromptEngine.render("creative-writer", { topic: "Space exploration" })

# Override temperature for more creativity
params = rendered.to_openai_params(temperature: 0.9)
creative_response = client.chat(parameters: params)

# Override for more deterministic output
params = rendered.to_openai_params(temperature: 0.1)
factual_response = client.chat(parameters: params)
```

### Working with Different Model Types

```ruby
# Chat models (most common)
chat_response = rendered.execute_with(chat_client)

# Completion models (older style)
# Extract just the content for completion APIs
completion_response = completion_client.complete(
  prompt: rendered.content,
  max_tokens: rendered.max_tokens,
  temperature: rendered.temperature
)

# Embedding models
embedding_client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])
embedding_response = embedding_client.embeddings(
  parameters: {
    model: "text-embedding-ada-002",
    input: rendered.content
  }
)
```

### Handling Responses

Different providers return responses in different formats:

```ruby
# OpenAI response handling
openai_response = rendered.execute_with(openai_client)
content = openai_response.dig("choices", 0, "message", "content")
usage = openai_response["usage"]

# Anthropic response handling
anthropic_response = rendered.execute_with(anthropic_client)
content = anthropic_response.dig("content", 0, "text")
usage = anthropic_response["usage"]

# RubyLLM provides a unified response interface
rubyllm_response = rendered.execute_with(rubyllm_client)
content = rubyllm_response.content
tokens = rubyllm_response.input_tokens + rubyllm_response.output_tokens
```

## Best Practices

1. **Use execute_with for simplicity**: Unless you need fine-grained control, `execute_with` handles most use cases automatically.

2. **Cache rendered prompts**: If using the same prompt multiple times, render once and reuse:
   ```ruby
   @support_prompt ||= PromptEngine.render("support-base", base_variables)
   response = @support_prompt.execute_with(client, additional_vars)
   ```

3. **Handle errors gracefully**:
   ```ruby
   begin
     response = rendered.execute_with(client)
   rescue => e
     Rails.logger.error "LLM Error: #{e.message}"
     # Fallback behavior
   end
   ```

4. **Use appropriate models**: Override the model when needed:
   ```ruby
   # Use a faster model for simple tasks
   params = rendered.to_openai_params(model: "gpt-3.5-turbo")
   
   # Use a more capable model for complex tasks
   params = rendered.to_openai_params(model: "gpt-4-turbo")
   ```

5. **Monitor token usage**: Track usage for cost management:
   ```ruby
   response = rendered.execute_with(client)
   Rails.logger.info "Tokens used: #{response['usage']['total_tokens']}"
   ```

## Complete Example

Here's a full example using a rendered prompt in a Rails service:

```ruby
class CustomerSupportService
  def initialize
    @client = OpenAI::Client.new(access_token: Rails.application.credentials.openai_api_key)
  end

  def handle_ticket(customer_name:, issue:, context: nil)
    # Render the prompt with variables
    rendered = PromptEngine.render("customer-support",
      { 
        customer_name: customer_name,
        issue: issue,
        context: context || "No additional context"
      },
      options: { 
        temperature: 0.3,  # Lower temperature for consistent support responses
        model: "gpt-4"     # Use GPT-4 for better understanding
      }
    )

    # Log what we're sending
    Rails.logger.info "Support prompt for #{customer_name}: #{rendered.content.truncate(100)}"

    # Execute with additional options
    response = rendered.execute_with(@client, 
      presence_penalty: 0.1,
      frequency_penalty: 0.1
    )

    # Extract and return the response
    ai_response = response.dig("choices", 0, "message", "content")
    
    # Store the interaction
    SupportInteraction.create!(
      customer_name: customer_name,
      issue: issue,
      prompt_version: rendered.version,
      ai_response: ai_response,
      tokens_used: response.dig("usage", "total_tokens")
    )

    ai_response
  rescue => e
    Rails.logger.error "Support AI Error: #{e.message}"
    "I apologize, but I'm having trouble processing your request. Please contact human support."
  end
end

# Usage
service = CustomerSupportService.new
response = service.handle_ticket(
  customer_name: "Alice Johnson",
  issue: "Cannot reset password",
  context: "Customer has tried resetting 3 times today"
)
```

This documentation covers all the current integration capabilities of PromptEngine's RenderedPrompt class, providing developers with multiple options for integrating with their preferred LLM providers.