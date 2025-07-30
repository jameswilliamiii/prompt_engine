# Test Implementation Plan for Missing LLM Integration Tests

This document provides a detailed implementation plan for adding the missing test coverage identified in MISSING-TESTS.md.

## Overview

All missing tests are for methods in `lib/prompt_engine/rendered_prompt.rb`. These methods are fully implemented but lack test coverage. No unimplemented features were found.

## 1. Testing `execute_with` Method (Lines 85-96)

### Implementation Location
- **File**: `lib/prompt_engine/rendered_prompt.rb`
- **Lines**: 85-96
- **Purpose**: Automatic client detection and execution based on class name pattern matching

### Current Implementation
```ruby
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
```

### Test Strategy

#### Test File Location
Create tests in: `spec/lib/rendered_prompt_spec.rb` (add to existing file)

#### Test Cases Required

1. **OpenAI Client Detection**
   - Create a mock object with class name containing "OpenAI"
   - Verify it calls `to_openai_params` with options
   - Verify it calls `client.chat(parameters: params)`
   - Test with class names: "OpenAI::Client", "MyOpenAIWrapper", "OpenAI"

2. **Anthropic Client Detection**
   - Create a mock object with class name containing "Anthropic"
   - Verify it calls `to_ruby_llm_params` with options
   - Verify it calls `client.chat(**params)` (note the splat)
   - Test with class names: "Anthropic::Client", "AnthropicAPI"

3. **RubyLLM Client Detection**
   - Create a mock object with class name containing "RubyLLM"
   - Verify it calls `to_ruby_llm_params` with options
   - Verify it calls `client.chat(**params)`
   - Test with class names: "RubyLLM::Provider", "MyRubyLLMClient"

4. **Unknown Client Error**
   - Create a mock object with unrecognized class name
   - Verify it raises ArgumentError with message "Unknown client type: UnknownClient"
   - Test with class names: "RandomAPI", "SomeOtherClient"

5. **Options Passing**
   - Verify additional options are passed through to parameter methods
   - Test with options like `{ stream: true, tools: [...] }`

#### Implementation Example
```ruby
describe "#execute_with" do
  let(:rendered_prompt) { described_class.new(prompt, rendered_data, {}) }
  
  context "with OpenAI client" do
    let(:openai_client) do
      double("OpenAI::Client", class: double(name: "OpenAI::Client"))
    end
    
    it "uses OpenAI parameters and calls chat with parameters key" do
      allow(rendered_prompt).to receive(:to_openai_params)
        .with(stream: true)
        .and_return({ model: "gpt-4", messages: [...] })
      
      expect(openai_client).to receive(:chat)
        .with(parameters: { model: "gpt-4", messages: [...] })
      
      rendered_prompt.execute_with(openai_client, stream: true)
    end
  end
end
```

## 2. Testing `messages` Method (Lines 51-56)

### Implementation Location
- **File**: `lib/prompt_engine/rendered_prompt.rb`
- **Lines**: 51-56
- **Purpose**: Format messages array for chat-based models

### Current Implementation
```ruby
def messages
  msgs = []
  msgs << { role: "system", content: system_message } if system_message.present?
  msgs << { role: "user", content: content }
  msgs
end
```

### Test Strategy

#### Test Cases Required

1. **With System Message**
   - Create rendered prompt with system_message
   - Verify array contains two messages
   - Verify first message has role: "system" and correct content
   - Verify second message has role: "user" and correct content
   - Verify ordering (system first, then user)

2. **Without System Message (nil)**
   - Create rendered prompt with nil system_message
   - Verify array contains only one message
   - Verify message has role: "user" and correct content

3. **Without System Message (empty string)**
   - Create rendered prompt with empty string system_message
   - Verify array contains only one message (empty string is not present)

4. **With Override System Message**
   - Create rendered prompt with overrides containing system_message
   - Verify the override system_message is used in the messages array

#### Implementation Example
```ruby
describe "#messages" do
  context "with system message" do
    let(:rendered_data) do
      {
        content: "Hello world",
        system_message: "You are a helpful assistant",
        # ... other fields
      }
    end
    
    it "returns array with system and user messages" do
      messages = rendered_prompt.messages
      
      expect(messages).to eq([
        { role: "system", content: "You are a helpful assistant" },
        { role: "user", content: "Hello world" }
      ])
    end
  end
  
  context "without system message" do
    let(:rendered_data) do
      {
        content: "Hello world",
        system_message: nil,
        # ... other fields
      }
    end
    
    it "returns array with only user message" do
      messages = rendered_prompt.messages
      
      expect(messages).to eq([
        { role: "user", content: "Hello world" }
      ])
    end
  end
end
```

## 3. Testing `to_openai_params` Method (Lines 59-69)

### Implementation Location
- **File**: `lib/prompt_engine/rendered_prompt.rb`
- **Lines**: 59-69
- **Purpose**: Format parameters for OpenAI API compatibility

### Current Implementation
```ruby
def to_openai_params(**additional_options)
  base_params = {
    model: model || "gpt-4",
    messages: messages,
    temperature: temperature,
    max_tokens: max_tokens
  }.compact
  
  base_params.merge(additional_options)
end
```

### Test Strategy

#### Test Cases Required

1. **Base Parameters**
   - Verify includes model, messages, temperature, max_tokens
   - Verify calls `messages` method to get messages array
   - Verify structure matches OpenAI API format

2. **Default Model**
   - When model is nil, verify it defaults to "gpt-4"
   - When model is provided, verify it uses the provided model

3. **Compact Behavior**
   - Verify nil values are removed from the hash
   - Test with nil temperature and max_tokens

4. **Additional Options Merging**
   - Test merging with tools array
   - Test merging with functions array
   - Test merging with response_format
   - Verify additional options override base params if same key

5. **Override Behavior**
   - Test that overrides from constructor affect the output
   - Verify override model/temperature/max_tokens are used

#### Implementation Example
```ruby
describe "#to_openai_params" do
  context "with all parameters" do
    it "returns OpenAI-formatted parameters" do
      params = rendered_prompt.to_openai_params
      
      expect(params).to include(
        model: "gpt-4",
        messages: [
          { role: "system", content: "You are a helpful assistant" },
          { role: "user", content: "Hello Alice" }
        ],
        temperature: 0.7,
        max_tokens: 1000
      )
    end
  end
  
  context "with nil model" do
    let(:rendered_data) do
      super().merge(model: nil)
    end
    
    it "defaults to gpt-4" do
      params = rendered_prompt.to_openai_params
      expect(params[:model]).to eq("gpt-4")
    end
  end
  
  context "with additional options" do
    it "merges additional options" do
      params = rendered_prompt.to_openai_params(
        tools: [{ type: "function", function: {...} }],
        stream: true
      )
      
      expect(params).to include(
        tools: [{ type: "function", function: {...} }],
        stream: true
      )
    end
  end
end
```

## 4. Testing `to_ruby_llm_params` Method (Lines 72-82)

### Implementation Location
- **File**: `lib/prompt_engine/rendered_prompt.rb`
- **Lines**: 72-82
- **Purpose**: Format parameters for RubyLLM/Anthropic compatibility

### Current Implementation
```ruby
def to_ruby_llm_params(**additional_options)
  base_params = {
    messages: messages,
    model: model || "gpt-4",
    temperature: temperature,
    max_tokens: max_tokens
  }.compact
  
  base_params.merge(additional_options)
end
```

### Test Strategy

#### Test Cases Required

1. **Base Parameters**
   - Verify includes messages, model, temperature, max_tokens
   - Note different key order from OpenAI (messages first)
   - Verify structure is compatible with RubyLLM

2. **Default Model**
   - When model is nil, verify it defaults to "gpt-4"
   - Test with Anthropic models (e.g., "claude-3-opus")

3. **Compact Behavior**
   - Verify nil values are removed
   - Test with various nil parameters

4. **Additional Options**
   - Test Anthropic-specific options
   - Test RubyLLM-specific options
   - Verify merging behavior

5. **Comparison with OpenAI Format**
   - Verify key differences (if any) between formats
   - Ensure both methods use same `messages` method

#### Implementation Example
```ruby
describe "#to_ruby_llm_params" do
  context "with all parameters" do
    it "returns RubyLLM-formatted parameters" do
      params = rendered_prompt.to_ruby_llm_params
      
      expect(params).to include(
        messages: [
          { role: "system", content: "You are a helpful assistant" },
          { role: "user", content: "Hello Alice" }
        ],
        model: "gpt-4",
        temperature: 0.7,
        max_tokens: 1000
      )
    end
  end
  
  context "parameter ordering" do
    it "has messages as the first key" do
      params = rendered_prompt.to_ruby_llm_params
      expect(params.keys.first).to eq(:messages)
    end
  end
end
```

## 5. Integration Tests

### Additional Integration Test Cases

1. **End-to-End with Real-like Clients**
   - Create more realistic mock clients
   - Test full flow from render to execution
   - Verify error handling in realistic scenarios

2. **Version and Status Interaction**
   - Test how version/status affect the LLM parameters
   - Ensure consistent behavior across all methods

### Test File Location
Consider creating: `spec/integration/llm_integration_spec.rb`

## 6. Test Data Setup

### Factory Updates
Update `spec/factories/rendered_prompts.rb` (or create if doesn't exist):

```ruby
FactoryBot.define do
  factory :rendered_prompt, class: "PromptEngine::RenderedPrompt" do
    transient do
      prompt { create(:prompt) }
      content { "Rendered content" }
      system_message { "System message" }
      model { "gpt-4" }
      temperature { 0.7 }
      max_tokens { 1000 }
      parameters_used { {} }
      version_number { 1 }
      overrides { {} }
    end
    
    initialize_with do
      rendered_data = {
        content: content,
        system_message: system_message,
        model: model,
        temperature: temperature,
        max_tokens: max_tokens,
        parameters_used: parameters_used,
        version_number: version_number
      }
      new(prompt, rendered_data, overrides)
    end
  end
end
```

## 7. Test Helpers

### Mock Client Helpers
Create helper methods in `spec/support/llm_client_helpers.rb`:

```ruby
module LLMClientHelpers
  def mock_openai_client(class_name: "OpenAI::Client")
    double(class_name, class: double(name: class_name))
  end
  
  def mock_anthropic_client(class_name: "Anthropic::Client")
    double(class_name, class: double(name: class_name))
  end
  
  def mock_ruby_llm_client(class_name: "RubyLLM::Provider")
    double(class_name, class: double(name: class_name))
  end
end

RSpec.configure do |config|
  config.include LLMClientHelpers
end
```

## 8. Coverage Goals

After implementing these tests:
- Target 100% line coverage for the four methods
- Target 100% branch coverage (all conditionals tested)
- Ensure all edge cases are covered
- Add tests for any error conditions

## 9. Implementation Order

Recommended order for implementing tests:
1. `messages` - Simplest, foundational for others
2. `to_openai_params` - Builds on messages
3. `to_ruby_llm_params` - Similar to OpenAI
4. `execute_with` - Most complex, depends on others

## 10. Running and Verifying

After implementation:
```bash
# Run specific tests
bundle exec rspec spec/lib/rendered_prompt_spec.rb -e "execute_with"
bundle exec rspec spec/lib/rendered_prompt_spec.rb -e "messages"

# Check coverage
bundle exec rspec
open coverage/index.html
# Verify lib/prompt_engine/rendered_prompt.rb shows 100% coverage
```

## Summary

All four methods are fully implemented and functional. No unimplemented features were found. The testing gap is purely in test coverage, not in functionality. Following this plan will bring these critical LLM integration methods to 100% test coverage, ensuring reliability and preventing regressions.