# PromptEngine Method Signature

As of version 2.0, PromptEngine uses a hybrid approach combining positional and keyword arguments for the `render` method to clearly separate prompt variables from rendering options.

## Method Signature

```ruby
PromptEngine.render(slug, variables = {}, options: {})
```

### Parameters

1. **slug** (String) - Required positional argument
   - The unique identifier for the prompt to render

2. **variables** (Hash) - Optional positional argument, defaults to `{}`
   - Variables to interpolate in the prompt template
   - These are the values that replace `{{variable_name}}` in your prompts

3. **options:** (Hash) - Optional keyword argument, defaults to `{}`
   - Rendering configuration options:
     - `:status` - Filter by prompt status ('draft', 'active', 'archived'), defaults to 'active'
     - `:model` - Override the prompt's default model
     - `:temperature` - Override the prompt's default temperature
     - `:max_tokens` - Override the prompt's default max_tokens
     - `:version` - Load a specific version number

## Examples

### Basic Usage

```ruby
# Simple render with just slug (no vars, no options)
result = PromptEngine.render("simple-greeting")

# Render with variables only
result = PromptEngine.render("welcome-email", 
  { customer_name: "John", product: "Premium Plan" }
)

# Render with options only (no variables)
result = PromptEngine.render("draft-prompt",
  options: { status: "draft" }
)

# Render with empty variables hash when using options
result = PromptEngine.render("simple-greeting", {}, 
  options: { temperature: 0.9 }
)
```

### With Options

```ruby
# Render a draft prompt with variables
result = PromptEngine.render("new-feature",
  { feature_name: "AI Assistant", user_name: "Beta Tester" },
  options: { status: "draft" }
)

# Override model settings
result = PromptEngine.render("email-writer",
  { subject: "Welcome", recipient: "Alice" },
  options: { model: "gpt-4-turbo", temperature: 0.9 }
)

# Load a specific version
result = PromptEngine.render("onboarding",
  { user_name: "Bob" },
  options: { version: 3 }
)

# Combine multiple options
result = PromptEngine.render("complex-prompt",
  { name: "Charlie", task: "Summarize this document" },
  options: { status: "draft", model: "claude-3", temperature: 0.7, max_tokens: 2000 }
)
```

## Why This Hybrid Approach?

The hybrid positional/keyword argument approach provides several benefits:

1. **Clear Separation**: Variables and options are clearly separated, avoiding namespace collisions
2. **No Conflicts**: Prompt variables can be named anything (including "status", "model", etc.) without conflicting with options
3. **Explicit Intent**: The `options:` keyword makes it crystal clear these are configuration parameters
4. **Flexibility**: Can skip variables entirely when only providing options
5. **Ruby Idiomatic**: This pattern is common and well-understood in Ruby APIs

## All Supported Usage Patterns

```ruby
# 1. Just slug (no variables, no options)
PromptEngine.render("static-prompt")

# 2. Slug with variables (no options)
PromptEngine.render("greeting", { name: "Alice" })

# 3. Slug with variables and options
PromptEngine.render("welcome", 
  { name: "Bob" }, 
  options: { status: "draft", model: "gpt-4" }
)

# 4. Slug with options only (no variables)
PromptEngine.render("archived-prompt", 
  options: { status: "archived" }
)
```

## Edge Cases

### Empty Variables with Options

```ruby
# When you have no variables but want to specify options
# Option 1: Skip variables entirely
result = PromptEngine.render("static-prompt", 
  options: { status: "archived" }
)

# Option 2: Explicit empty hash (if you prefer being explicit)
result = PromptEngine.render("static-prompt", {}, 
  options: { status: "archived" }
)
```

### Variables That Look Like Options

```ruby
# No ambiguity - "status" and "temperature" here are clearly prompt variables
# because they're in the variables hash, not in options:
result = PromptEngine.render("status-reporter",
  { status: "System is operational", temperature: "Normal" },
  options: { model: "gpt-4", temperature: 0.3 }  # "temperature" as option
)
```

## Best Practices

1. Always use hashes for variables, even with a single variable:
   ```ruby
   # Good
   PromptEngine.render("greeting", { name: "Alice" })
   
   # Less clear (though still valid)
   PromptEngine.render("greeting", name: "Alice")  # Ruby will convert to hash
   ```

2. Skip variables when not needed:
   ```ruby
   # Best - cleaner when you only have options
   PromptEngine.render("prompt", options: { status: "draft" })
   
   # Also works - explicit empty hash
   PromptEngine.render("prompt", {}, options: { status: "draft" })
   ```

3. Use meaningful variable names that describe the content:
   ```ruby
   # Good
   PromptEngine.render("email", 
     { recipient_name: "John", email_subject: "Welcome" }
   )
   
   # Less descriptive
   PromptEngine.render("email", 
     { name: "John", subject: "Welcome" }
   )
   ```