# PromptEngine Method Signature

As of version 2.0, PromptEngine uses a positional argument approach for the `render` method to clearly separate prompt variables from rendering options.

## Method Signature

```ruby
PromptEngine.render(slug, variables = {}, options = {})
```

### Parameters

1. **slug** (String) - Required
   - The unique identifier for the prompt to render

2. **variables** (Hash) - Optional, defaults to `{}`
   - Variables to interpolate in the prompt template
   - These are the values that replace `{{variable_name}}` in your prompts

3. **options** (Hash) - Optional, defaults to `{}`
   - Rendering configuration options:
     - `:status` - Filter by prompt status ('draft', 'active', 'archived'), defaults to 'active'
     - `:model` - Override the prompt's default model
     - `:temperature` - Override the prompt's default temperature
     - `:max_tokens` - Override the prompt's default max_tokens
     - `:version` - Load a specific version number

## Examples

### Basic Usage

```ruby
# Simple render with variables
result = PromptEngine.render("welcome-email", 
  { customer_name: "John", product: "Premium Plan" }
)

# Render without variables
result = PromptEngine.render("simple-greeting", {})

# Or simply
result = PromptEngine.render("simple-greeting")
```

### With Options

```ruby
# Render a draft prompt
result = PromptEngine.render("new-feature",
  { feature_name: "AI Assistant", user_name: "Beta Tester" },
  { status: "draft" }
)

# Override model settings
result = PromptEngine.render("email-writer",
  { subject: "Welcome", recipient: "Alice" },
  { model: "gpt-4-turbo", temperature: 0.9 }
)

# Load a specific version
result = PromptEngine.render("onboarding",
  { user_name: "Bob" },
  { version: 3 }
)

# Combine multiple options
result = PromptEngine.render("complex-prompt",
  { name: "Charlie", task: "Summarize this document" },
  { status: "draft", model: "claude-3", temperature: 0.7, max_tokens: 2000 }
)
```

## Why This Approach?

The positional argument approach provides several benefits:

1. **Clear Separation**: Variables and options are clearly separated, avoiding namespace collisions
2. **No Conflicts**: Prompt variables can be named anything (including "status", "model", etc.) without conflicting with options
3. **Explicit Intent**: It's immediately clear which arguments are prompt variables vs configuration
4. **Type Safety**: Easier to validate and type-check in future versions

## Migration from Keyword Arguments

If you're upgrading from an older version that used keyword arguments:

```ruby
# Old style (pre-2.0)
PromptEngine.render("welcome", 
  name: "John", 
  status: "draft",  # Ambiguous - is this a variable or option?
  model: "gpt-4"
)

# New style (2.0+)
PromptEngine.render("welcome",
  { name: "John" },        # Clear: this is a variable
  { status: "draft", model: "gpt-4" }  # Clear: these are options
)
```

## Edge Cases

### Empty Variables with Options

```ruby
# When you have no variables but want to specify options
result = PromptEngine.render("static-prompt", {}, { status: "archived" })
```

### Variables That Look Like Options

```ruby
# No ambiguity - "status" here is clearly a prompt variable
result = PromptEngine.render("status-reporter",
  { status: "System is operational", temperature: "Normal" },
  { model: "gpt-4", temperature: 0.3 }  # "temperature" as option
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

2. Be explicit with empty variables when using options:
   ```ruby
   # Good - intent is clear
   PromptEngine.render("prompt", {}, { status: "draft" })
   
   # Works but less clear
   PromptEngine.render("prompt", nil, { status: "draft" })
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