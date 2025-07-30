# Missing Tests for LLM Integration Features

This document outlines the missing test coverage for the LLM integration features documented in `docs/PROMPT-USAGE.md`. After analyzing the current test suite, the following critical methods and features lack test coverage.

## Summary

The `RenderedPrompt` class has several important methods for LLM integration that are **completely untested**. These methods are crucial for the functionality described in the usage documentation but have no corresponding tests.

## Missing Test Coverage

### 1. `execute_with` Method (Lines 85-96)

**Location**: `lib/prompt_engine/rendered_prompt.rb`

This is the primary method for automatic client detection and execution, but has **zero test coverage**.

Missing tests for:
- OpenAI client detection (when `client.class.name` matches `/OpenAI/`)
- Anthropic client detection (when `client.class.name` matches `/Anthropic/`)
- RubyLLM client detection (when `client.class.name` matches `/RubyLLM/`)
- Passing additional options to the client
- Error handling for unknown client types (should raise `ArgumentError`)
- Correct method calls for each client type:
  - OpenAI: `client.chat(parameters: params)`
  - RubyLLM/Anthropic: `client.chat(**params)`

### 2. `messages` Method (Lines 51-56)

**Location**: `lib/prompt_engine/rendered_prompt.rb`

This method formats messages for chat-based models but is **not tested**.

Missing tests for:
- Correct array structure with role/content hashes
- System message inclusion when present
- System message exclusion when nil/blank
- Proper ordering (system first, then user)

### 3. `to_openai_params` Method (Lines 59-69)

**Location**: `lib/prompt_engine/rendered_prompt.rb`

This method prepares parameters for OpenAI API but has **no tests**.

Missing tests for:
- Base parameter structure (model, messages, temperature, max_tokens)
- Default model value ("gpt-4") when not specified
- `.compact` removing nil values
- Merging additional options passed as arguments
- Preservation of additional OpenAI-specific options (tools, functions, response_format)

### 4. `to_ruby_llm_params` Method (Lines 72-82)

**Location**: `lib/prompt_engine/rendered_prompt.rb`

This method prepares parameters for RubyLLM but is **not tested**.

Missing tests for:
- Base parameter structure for RubyLLM format
- Default model value when not specified
- `.compact` removing nil values
- Merging additional options
- Compatibility with Anthropic format (same structure)

## Currently Tested Features

For context, the following features ARE tested:
- Basic accessors (content, system_message, model, temperature, max_tokens)
- Status and version accessors
- Options accessor
- Parameter access methods (parameters, parameter, parameter_names, parameter_values)
- The `to_h` method
- Override functionality
- Backward compatibility

## Impact

Without tests for these integration methods:
1. **No confidence** that the documented OpenAI integration actually works
2. **No confidence** that the documented Anthropic integration actually works
3. **No confidence** that the documented RubyLLM integration actually works
4. **No protection** against breaking changes to these critical methods
5. **No verification** that client detection logic works correctly
6. **No verification** that error handling works for unknown clients

## Recommended Test Structure

Tests should be added to verify:

### For `execute_with`:
```ruby
describe "#execute_with" do
  context "with OpenAI client" do
    # Test client detection
    # Test parameter formatting
    # Test method call with correct arguments
  end
  
  context "with Anthropic client" do
    # Similar tests
  end
  
  context "with RubyLLM client" do
    # Similar tests
  end
  
  context "with unknown client" do
    # Test ArgumentError is raised
  end
  
  context "with additional options" do
    # Test options are passed through
  end
end
```

### For `messages`:
```ruby
describe "#messages" do
  context "with system message" do
    # Test array structure
  end
  
  context "without system message" do
    # Test array structure
  end
end
```

### For `to_openai_params` and `to_ruby_llm_params`:
```ruby
describe "#to_openai_params" do
  # Test base structure
  # Test with additional options
  # Test nil handling
  # Test default values
end
```

## Conclusion

The LLM integration features are a critical part of PromptEngine's functionality, but they currently lack any test coverage. This is a significant gap that should be addressed before relying on these features in production.