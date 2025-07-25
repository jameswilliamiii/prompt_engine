# PromptEngine Better API Design

## Overview

This document outlines the new API design for PromptEngine with the following features:

1. Object-oriented API that returns `RenderedPrompt` instances
2. Slug-based prompt identification for clean URLs and references
3. Native integration with LLM libraries (RubyLLM, ruby-openai, etc.)
4. Runtime overrides for model parameters
5. Version support for A/B testing and rollbacks
6. Advanced LLM features (tools, functions, response formats)

## API Design

### Core API

```ruby
# Finding by slug (required)
prompt = PromptEngine.find("test-prompt-with-vars")
rendered = prompt.render(var1: "value1", var2: "value2")

# Or in one step
rendered = PromptEngine.render("test-prompt-with-vars", var1: "value1", var2: "value2")

# Override model settings at render time
rendered = PromptEngine.render("test-prompt-with-vars",
  var1: "value1",
  var2: "value2",
  model: "claude-3-opus-20240229",  # Override default model
  temperature: 0.9,                  # Override temperature
  max_tokens: 2000,                  # Override max tokens
  version: 3                         # Use specific version (optional)
)

# Direct integration with LLM clients
response = rendered.execute_with(openai_client)
response = rendered.execute_with(ruby_llm_client)

# With additional options (tools, functions, etc.)
response = rendered.execute_with(openai_client,
  tools: [...],
  tool_choice: "auto",
  response_format: { type: "json_object" }
)

# Or explicit parameter conversion
response = openai_client.chat(parameters: rendered.to_openai_params)
response = ruby_llm_client.chat(**rendered.to_ruby_llm_params)

# Access rendered values
rendered.content         # => "Rendered content with value1 and value2"
rendered.system_message  # => "System message"
rendered.messages        # => [{ role: "system", content: "..." }, { role: "user", content: "..." }]
rendered.model          # => "claude-3-opus-20240229" (overridden)
rendered.temperature    # => 0.9 (overridden)
rendered.max_tokens     # => 2000 (overridden)
rendered.version_number # => 3 (if version specified)
```

## Implementation Plan

### 1. Add Slug Support to Prompt Model

```ruby
# Migration
class AddSlugToPromptEnginePrompts < ActiveRecord::Migration[7.1]
  def change
    add_column :prompt_engine_prompts, :slug, :string
    add_index :prompt_engine_prompts, :slug, unique: true
  end
end

# Model updates
module PromptEngine
  class Prompt < ApplicationRecord
    validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9-]+\z/ }

    before_validation :generate_slug_from_name, on: :create

    private

    def generate_slug_from_name
      self.slug ||= name&.parameterize
    end
  end
end
```

### 2. Create RenderedPrompt Class

```ruby
# lib/prompt_engine/rendered_prompt.rb
module PromptEngine
  class RenderedPrompt
    attr_reader :prompt, :content, :system_message, :model,
                :temperature, :max_tokens, :variables_used, :overrides,
                :version_number

    def initialize(prompt, rendered_data, overrides = {})
      @prompt = prompt
      @content = rendered_data[:content]
      @system_message = rendered_data[:system_message]
      @variables_used = rendered_data[:parameters_used]
      @overrides = overrides
      @version_number = rendered_data[:version_number]

      # Apply overrides for model settings
      @model = overrides[:model] || rendered_data[:model]
      @temperature = overrides[:temperature] || rendered_data[:temperature]
      @max_tokens = overrides[:max_tokens] || rendered_data[:max_tokens]
    end

    # Returns messages array for chat-based models
    def messages
      msgs = []
      msgs << { role: "system", content: system_message } if system_message.present?
      msgs << { role: "user", content: content }
      msgs
    end

    # For OpenAI gem compatibility
    def to_openai_params(**additional_options)
      base_params = {
        model: model || "gpt-4",
        messages: messages,
        temperature: temperature,
        max_tokens: max_tokens
      }.compact

      # Merge with additional options (tools, functions, response_format, etc.)
      base_params.merge(additional_options)
    end

    # For RubyLLM compatibility
    def to_ruby_llm_params(**additional_options)
      base_params = {
        messages: messages,
        model: model || "gpt-4",
        temperature: temperature,
        max_tokens: max_tokens
      }.compact

      # Merge with additional options
      base_params.merge(additional_options)
    end

    # Automatic client detection and execution
    def execute_with(client, **options)
      case client.class.name
      when /OpenAI/
        params = to_openai_params(**options)
        client.chat(parameters: params)
      when /RubyLLM/, /Anthropic/
        params = to_ruby_llm_params(**options)
        client.chat(**params)
      else
        raise ArgumentError, "Unknown client type: #{client.class.name}"
      end
    end

    # Convenience methods
    def to_h
      {
        content: content,
        system_message: system_message,
        model: model,
        temperature: temperature,
        max_tokens: max_tokens,
        messages: messages,
        overrides: overrides,
        version_number: version_number
      }
    end

    def inspect
      version_info = version_number ? " version=#{version_number}" : ""
      "#<PromptEngine::RenderedPrompt prompt=#{prompt.slug}#{version_info} variables=#{variables_used.keys} overrides=#{overrides.keys}>"
    end
  end
end
```

### 3. Update Prompt Model

```ruby
module PromptEngine
  class Prompt < ApplicationRecord
    # ... existing code ...

    # Reserved keys that are overrides, not variables
    OVERRIDE_KEYS = %i[model temperature max_tokens version].freeze

    # New render method that returns RenderedPrompt
    def render(**options)
      # Separate variables from overrides
      overrides = options.slice(*OVERRIDE_KEYS)
      variables = options.except(*OVERRIDE_KEYS)

      # Handle version specification
      if overrides[:version]
        version_number = overrides.delete(:version)
        return render_version(version_number, variables: variables, overrides: overrides)
      end

      rendered_data = render_with_params(variables)

      # Handle errors
      if rendered_data[:error]
        raise RenderError, rendered_data[:error]
      end

      # Add current version number
      rendered_data[:version_number] = current_version&.version_number

      RenderedPrompt.new(self, rendered_data, overrides)
    end

    # Render a specific version
    def render_version(version_number, variables: {}, overrides: {})
      version = versions.find_by!(version_number: version_number)

      # Use version's content and settings
      detector = PromptEngine::VariableDetector.new(version.content)
      rendered_content = detector.render(variables)

      rendered_data = {
        content: rendered_content,
        system_message: version.system_message,
        model: version.model,
        temperature: version.temperature,
        max_tokens: version.max_tokens,
        parameters_used: variables,
        version_number: version.version_number
      }

      RenderedPrompt.new(self, rendered_data, overrides)
    end

    # Class method for finding by slug
    def self.find_by_slug!(slug)
      find_by!(slug: slug, status: "active")
    end
  end
end
```

### 4. Update PromptEngine Module

```ruby
module PromptEngine
  class << self
    # Render a prompt by slug with variables and options
    def render(slug, **options)
      prompt = find(slug)
      prompt.render(**options)
    end

    # Find a prompt by slug
    def find(slug)
      Prompt.find_by_slug!(slug)
    end

    # Alias for array-like access
    def [](slug)
      find(slug)
    end
  end
end
```

### 5. Add Custom Errors

```ruby
# lib/prompt_engine/errors.rb
module PromptEngine
  class Error < StandardError; end
  class RenderError < Error; end
  class PromptNotFoundError < Error; end
end
```

## Usage Examples

### Basic Usage

```ruby
# Find and render separately
prompt = PromptEngine.find("welcome-email")
rendered = prompt.render(user_name: "John", company: "Acme Corp")

# Or all at once
rendered = PromptEngine.render("welcome-email", user_name: "John", company: "Acme Corp")

# Using a specific version
rendered = PromptEngine.render("welcome-email",
  user_name: "John",
  company: "Acme Corp",
  version: 3  # Use version 3 instead of current
)

# Or with the prompt object
prompt = PromptEngine.find("welcome-email")
rendered = prompt.render(user_name: "John", version: 2)

# List available versions
prompt.versions.each do |v|
  puts "Version #{v.version_number}: #{v.change_description} (#{v.created_at})"
end
```

### With OpenAI

```ruby
client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])

# Basic usage
rendered = PromptEngine.render("blog-post-generator", topic: "Ruby on Rails")
response = rendered.execute_with(client)

# With model override
rendered = PromptEngine.render("blog-post-generator",
  topic: "Ruby on Rails",
  model: "gpt-4-turbo-preview",
  temperature: 0.8
)
response = rendered.execute_with(client)

# With function calling
functions = [
  {
    name: "get_weather",
    description: "Get the current weather",
    parameters: {
      type: "object",
      properties: {
        location: { type: "string", description: "City and state" },
        unit: { type: "string", enum: ["celsius", "fahrenheit"] }
      },
      required: ["location"]
    }
  }
]

rendered = PromptEngine.render("weather-assistant", query: "What's the weather?")
response = rendered.execute_with(client,
  functions: functions,
  function_call: "auto"
)

# With tools (newer API)
tools = [
  {
    type: "function",
    function: {
      name: "analyze_code",
      description: "Analyze code for issues",
      parameters: {
        type: "object",
        properties: {
          code: { type: "string" },
          language: { type: "string" }
        }
      }
    }
  }
]

rendered = PromptEngine.render("code-analyzer", code: ruby_code)
response = rendered.execute_with(client,
  tools: tools,
  tool_choice: "auto"
)

# With response format (JSON mode)
rendered = PromptEngine.render("data-extractor", text: document)
response = rendered.execute_with(client,
  response_format: { type: "json_object" }
)

# Streaming
rendered = PromptEngine.render("story-writer", prompt: "Write a story")
client.chat(
  parameters: rendered.to_openai_params(
    stream: proc do |chunk, _bytesize|
      print chunk.dig("choices", 0, "delta", "content")
    end
  )
)
```

### With RubyLLM

```ruby
# OpenAI through RubyLLM
openai = RubyLLM::OpenAI.new(api_key: ENV["OPENAI_API_KEY"])

# Basic usage
rendered = PromptEngine.render("code-reviewer", code: file_content)
response = rendered.execute_with(openai)

# With model override for Anthropic
anthropic = RubyLLM::Anthropic.new(api_key: ENV["ANTHROPIC_API_KEY"])
rendered = PromptEngine.render("code-reviewer",
  code: file_content,
  model: "claude-3-opus-20240229",
  max_tokens: 4000
)
response = rendered.execute_with(anthropic)

# With tools
tools = [
  {
    name: "execute_code",
    description: "Execute Ruby code",
    input_schema: {
      type: "object",
      properties: {
        code: { type: "string", description: "Ruby code to execute" }
      },
      required: ["code"]
    }
  }
]

rendered = PromptEngine.render("code-assistant", request: "Calculate fibonacci")
response = anthropic.chat(
  **rendered.to_ruby_llm_params(tools: tools)
)

# With system prompts and multiple messages
rendered = PromptEngine.render("conversational-ai", query: user_input)
messages = rendered.messages + [
  { role: "assistant", content: "Previous response..." },
  { role: "user", content: "Follow up question..." }
]

response = openai.chat(
  model: rendered.model,
  messages: messages,
  temperature: rendered.temperature
)

# Streaming with RubyLLM
rendered = PromptEngine.render("content-generator", topic: "AI Ethics")
anthropic.chat(
  **rendered.to_ruby_llm_params,
  stream: true
) do |event|
  print event.content_block_delta&.text
end
```

### Advanced Features

#### Version Management

```ruby
# A/B testing with different versions
version_a = PromptEngine.render("optimizer", text: input, version: 1)
version_b = PromptEngine.render("optimizer", text: input, version: 2)

# Compare performance
response_a = version_a.execute_with(client)
response_b = version_b.execute_with(client)

# Rollback to a known good version in production
begin
  rendered = PromptEngine.render("critical-prompt", data: user_data)
rescue => e
  # Fallback to stable version
  rendered = PromptEngine.render("critical-prompt", data: user_data, version: 5)
end

# Version-specific overrides
rendered = PromptEngine.render("assistant",
  query: "Help me",
  version: 3,              # Use version 3
  model: "gpt-4-turbo",    # But override its model
  temperature: 0.5         # And temperature
)
```

#### Model and Parameter Overrides

```ruby
# Override any model parameter at render time
rendered = PromptEngine.render("analyzer",
  text: document,
  model: "gpt-4-vision-preview",    # Switch to vision model
  temperature: 0.2,                  # More deterministic
  max_tokens: 8000                   # Larger response
)

# The overrides are accessible
puts rendered.model        # => "gpt-4-vision-preview"
puts rendered.overrides    # => { model: "gpt-4-vision-preview", temperature: 0.2, max_tokens: 8000 }
```

#### Complex Tool Integration

```ruby
# Define complex tools with nested schemas
tools = [
  {
    type: "function",
    function: {
      name: "search_database",
      description: "Search the database",
      parameters: {
        type: "object",
        properties: {
          query: { type: "string" },
          filters: {
            type: "object",
            properties: {
              date_range: {
                type: "object",
                properties: {
                  start: { type: "string", format: "date" },
                  end: { type: "string", format: "date" }
                }
              },
              categories: {
                type: "array",
                items: { type: "string" }
              }
            }
          },
          limit: { type: "integer", default: 10 }
        },
        required: ["query"]
      }
    }
  }
]

rendered = PromptEngine.render("search-assistant", request: user_query)
response = rendered.execute_with(client,
  tools: tools,
  tool_choice: { type: "function", function: { name: "search_database" } }
)
```

#### Multi-Provider Support

```ruby
# Same prompt, different providers
prompt = PromptEngine.find("universal-assistant")

# Render once, use with multiple providers
rendered = prompt.render(query: "Explain quantum computing")

# OpenAI
openai_response = rendered.execute_with(openai_client)

# Anthropic (with provider-specific options)
anthropic_response = rendered.execute_with(anthropic_client,
  metadata: { user_id: "123" }
)

# Cohere
cohere_response = rendered.execute_with(cohere_client,
  return_likelihoods: "GENERATION"
)
```

#### Conversation Management

```ruby
# Build conversations by extending messages
rendered = PromptEngine.render("chatbot", message: "Hello")

# Add to conversation history
conversation = rendered.messages
conversation << { role: "assistant", content: "Hi! How can I help?" }
conversation << { role: "user", content: "Tell me about Rails" }

# Continue conversation with context
response = client.chat(
  model: rendered.model,
  messages: conversation,
  temperature: rendered.temperature
)
```

#### Response Format Control

```ruby
# JSON responses
rendered = PromptEngine.render("structured-output", data: input)
response = rendered.execute_with(client,
  response_format: { type: "json_object" }
)

# With JSON schema (OpenAI beta)
schema = {
  type: "object",
  properties: {
    summary: { type: "string" },
    sentiment: { type: "string", enum: ["positive", "negative", "neutral"] },
    key_points: {
      type: "array",
      items: { type: "string" }
    }
  },
  required: ["summary", "sentiment", "key_points"]
}

response = rendered.execute_with(client,
  response_format: {
    type: "json_schema",
    json_schema: schema
  }
)
```

#### Parallel Execution

```ruby
# Render multiple prompts for parallel execution
prompts = ["summarizer", "analyzer", "classifier"].map do |slug|
  PromptEngine.render(slug, text: document)
end

# Execute in parallel
responses = prompts.map do |rendered|
  Thread.new { rendered.execute_with(client) }
end.map(&:value)
```

## Implementation Steps

1. **Database Changes**

   - Add slug column to prompts table (required, unique)
   - Add database index on slug for performance

2. **Model Updates**

   - Add slug validation and auto-generation
   - Implement version-aware render methods
   - Add OVERRIDE_KEYS constant

3. **New Classes**

   - Create RenderedPrompt class with LLM integrations
   - Add custom error classes

4. **Module Updates**

   - Simple slug-based API in PromptEngine module
   - Remove any name-based lookups

5. **Admin UI**
   - Update forms to support slug editing
   - Show slug in prompt listings
   - Add slug validation in UI

## Benefits

1. **Type Safety**: Working with objects instead of hashes provides better IDE support and runtime
   checks
2. **Extensibility**: Easy to add new methods and behaviors to RenderedPrompt
3. **Clean Integration**: Natural integration with LLM libraries and their advanced features
4. **Flexibility**: Override any model parameter at render time without modifying the prompt
5. **Advanced Features**: Full support for tools, functions, response formats, and streaming
6. **Multi-Provider**: Write once, use with any LLM provider
7. **Clean URLs**: Slug-based references (`/prompts/welcome-email`)
8. **Version Control**: Built-in support for using specific prompt versions

## Testing Support

The new API design makes testing easier and more robust:

```ruby
# In your specs
RSpec.describe MyService do
  let(:mock_prompt) { instance_double(PromptEngine::RenderedPrompt) }

  before do
    allow(PromptEngine).to receive(:render).and_return(mock_prompt)
    allow(mock_prompt).to receive(:execute_with).and_return(mock_response)
  end

  it "processes with custom tools" do
    expect(mock_prompt).to receive(:execute_with).with(
      anything,
      hash_including(tools: array_including(hash_including(type: "function")))
    )

    service.process_with_tools
  end
end

# Test prompt rendering without API calls
rendered = PromptEngine.render("test-prompt", var: "value")
expect(rendered.content).to include("value")
expect(rendered.model).to eq("gpt-4")

# Test with overrides
rendered = PromptEngine.render("test-prompt", var: "value", model: "claude-3")
expect(rendered.model).to eq("claude-3")
expect(rendered.overrides).to eq({ model: "claude-3" })
```

## Future Enhancements

1. **Built-in Streaming Interface**:

   ```ruby
   rendered.stream_with(client) do |chunk|
     print chunk
   end
   ```

2. **Validation and Cost Estimation**:

   ```ruby
   rendered.valid_for_model? # Check token limits
   rendered.estimated_tokens # Token counting
   rendered.estimated_cost   # Cost estimation
   rendered.fits_in_context?(additional_messages: [...])
   ```

3. **Chaining and Composition**:

   ```ruby
   # Chain prompts together
   summary = PromptEngine.render("summarizer", text: article)
   analysis = PromptEngine.render("analyzer", summary: summary.content)

   # Or with a pipeline
   result = PromptEngine.pipeline(
     ["summarizer", "analyzer", "formatter"],
     initial_input: { text: article }
   )
   ```

4. **Response Parsing and Validation**:

   ```ruby
   rendered = PromptEngine.render("classifier", text: input)
   response = rendered.execute_with(client)

   # Type-aware parsing based on response_format
   parsed = rendered.parse_response(response)

   # With schema validation
   rendered.validate_response(response) # => true/false
   rendered.response_errors(response)   # => ["missing required field: category"]
   ```

5. **Provider-Specific Optimizations**:

   ```ruby
   # Automatically adjust parameters for different providers
   rendered = PromptEngine.render("assistant", query: "Help me")

   # Auto-converts between provider formats
   rendered.to_openai_params   # => { max_tokens: 1000 }
   rendered.to_anthropic_params # => { max_tokens_to_sample: 1000 }
   rendered.to_cohere_params    # => { max_tokens: 1000 }
   ```
