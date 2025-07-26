# Parameter Access in RenderedPrompt

## Overview

When you render a prompt with variables using `PromptEngine.render`, the returned `RenderedPrompt` instance provides a clean, safe API for accessing the parameter values used during rendering.

## Usage Examples

### Basic Parameter Access

```ruby
# Render a prompt with parameters
rendered = PromptEngine.render("story-eval-test",
  type: "adventure",
  character: "wizard",
  place: "forest",
  user_id: 123,
  is_premium: true
)

# Access all parameters as a hash
rendered.parameters
# => {"type" => "adventure", "character" => "wizard", "place" => "forest", "user_id" => 123, "is_premium" => true}

# Access individual parameter values
rendered.parameter(:type)         # => "adventure"
rendered.parameter("character")   # => "wizard"
rendered.parameter(:user_id)      # => 123
rendered.parameter(:is_premium)   # => true

# Check if a parameter exists
rendered.parameter?(:character)   # => true
rendered.parameter?(:undefined)   # => false

# Get parameter names and values
rendered.parameter_names   # => ["type", "character", "place", "user_id", "is_premium"]
rendered.parameter_values  # => ["adventure", "wizard", "forest", 123, true]
```

### Why This Design?

This API design prioritizes:

1. **Safety**: No risk of overriding important methods like `content`, `model`, etc.
2. **Clarity**: Explicit methods make it clear you're accessing parameters
3. **Consistency**: Similar to Rails' `params.require(:key)` pattern
4. **Type Preservation**: Maintains original parameter types (strings, integers, booleans)

### Working with Parameters

```ruby
# Example: Building an audit log
rendered = PromptEngine.render("customer-support",
  customer_name: "Alice",
  issue_type: "billing",
  account_id: 12345
)

# Easy to iterate over all parameters
rendered.parameter_names.each do |name|
  audit_log.add_field(name, rendered.parameter(name))
end

# Or use the parameters hash directly
AuditLog.create!(
  prompt_slug: rendered.prompt.slug,
  parameters: rendered.parameters,
  response_content: rendered.content
)
```

### Checking Parameter Existence

```ruby
# Safe parameter access with defaults
customer_name = rendered.parameter(:customer_name) || "Guest"

# Conditional logic based on parameter presence
if rendered.parameter?(:premium_features)
  # Include premium content
end

# Validation example
required_params = [:customer_id, :issue_type]
missing = required_params.reject { |p| rendered.parameter?(p) }
raise "Missing required parameters: #{missing.join(', ')}" if missing.any?
```

### Integration Examples

#### With Logging

```ruby
rendered = PromptEngine.render("api-request", 
  endpoint: "/users", 
  method: "GET",
  user_id: 123
)

Rails.logger.info(
  "AI Request - Endpoint: #{rendered.parameter(:endpoint)}, " \
  "Method: #{rendered.parameter(:method)}, " \
  "User: #{rendered.parameter(:user_id)}"
)
```

#### With Analytics

```ruby
rendered = PromptEngine.render("product-description",
  product_id: 456,
  category: "electronics",
  brand: "TechCorp"
)

Analytics.track("prompt_rendered", {
  prompt_type: rendered.prompt.slug,
  product_category: rendered.parameter(:category),
  brand: rendered.parameter(:brand),
  parameter_count: rendered.parameter_names.length
})
```

#### With Background Jobs

```ruby
class ProcessAIResponseJob < ApplicationJob
  def perform(prompt_slug, parameters)
    rendered = PromptEngine.render(prompt_slug, **parameters)
    
    # Access specific parameters for job logic
    if rendered.parameter(:priority) == "high"
      # Process immediately
    else
      # Queue for batch processing
    end
  end
end
```

## API Reference

### Methods

- `parameters` - Returns the full hash of parameter key-value pairs
- `parameter(key)` - Returns the value for a specific parameter (accepts string or symbol)
- `parameter?(key)` - Returns true if the parameter exists
- `parameter_names` - Returns an array of all parameter names as strings
- `parameter_values` - Returns an array of all parameter values

### Accessing the Original Prompt

The rendered prompt instance provides access to the original prompt object:

```ruby
rendered = PromptEngine.render("customer-support", customer_name: "Alice")

# Access the original prompt
rendered.prompt         # => #<PromptEngine::Prompt>
rendered.prompt.slug    # => "customer-support"
rendered.prompt.name    # => "Customer Support"
rendered.prompt.status  # => "active"
```

## Best Practices

1. **Use symbols or strings consistently** - Both work, but pick one style
2. **Check existence with parameter?** before accessing optional parameters
3. **Use parameter_names for iteration** when you need to process all parameters
4. **Preserve the parameters hash** when storing for audit trails or debugging