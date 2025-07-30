# Prompt Status Filtering

PromptEngine now supports filtering prompts by status when rendering. This allows you to work with draft and archived prompts in addition to active ones.

## Default Behavior

By default, `PromptEngine.render` and `PromptEngine.find` will only look for **active** prompts:

```ruby
# Only finds prompts with status: "active"
PromptEngine.render("welcome-email", { user_name: "John" })
```

This ensures backward compatibility and prevents accidentally using draft or archived prompts in production.

## Specifying Status

You can override the default behavior by passing a `status` parameter:

```ruby
# Render a draft prompt
PromptEngine.render("welcome-email", 
  { user_name: "John" },
  options: { status: "draft" }
)

# Render an archived prompt
PromptEngine.render("old-welcome", 
  { user_name: "John" },
  options: { status: "archived" }
)

# Explicitly request active status
PromptEngine.render("welcome-email",
  { user_name: "John" },
  options: { status: "active" }
)
```

## Available Statuses

- **draft**: Prompts being worked on but not ready for production
- **active**: Production-ready prompts (default)
- **archived**: Old prompts kept for reference

## Usage Examples

### Testing Draft Prompts

```ruby
# In your staging environment or admin preview
result = PromptEngine.render("new-feature-prompt",
  { feature_name: "AI Assistant", user_name: "Beta Tester" },
  options: { status: "draft" }
)
```

### Accessing Historical Prompts

```ruby
# For audit or comparison purposes
old_version = PromptEngine.render("terms-of-service",
  { company_name: "Acme Corp" },
  options: { status: "archived" }
)
```

### Admin Interface / Playground

The playground can test prompts in any status:

```ruby
# In the playground controller
def execute
  result = PromptEngine.render(params[:slug],
    params[:variables] || {},
    options: { status: params[:status] || "active" }
  )
end
```

## Working with the Find Method

The `find` method also supports status filtering:

```ruby
# Find active prompt (default)
prompt = PromptEngine.find("welcome-email")

# Find draft prompt
prompt = PromptEngine.find("welcome-email-v2", status: "draft")

# Find any prompt regardless of status
prompt = PromptEngine.find("welcome-email", status: nil)
```

## Combining with Other Options

Status filtering works seamlessly with all other rendering options:

```ruby
result = PromptEngine.render("ai-prompt",
  # Variables
  { user_name: "Alice", task: "Write a story" },
  
  # Options including status and overrides
  options: { 
    status: "draft",
    model: "gpt-4-turbo",
    temperature: 0.8,
    max_tokens: 2000 
  }
)
```

## Version Rendering with Status

You can also specify a version along with status:

```ruby
# Render version 3 of a draft prompt
result = PromptEngine.render("feature-prompt",
  { feature: "New Dashboard" },
  options: { status: "draft", version: 3 }
)
```

## Best Practices

1. **Production Code**: Always use the default behavior (active only) unless you have a specific need
2. **Testing**: Use draft status for testing new prompts before making them active
3. **Archival**: Move old prompts to archived status instead of deleting them
4. **Explicit Status**: When in doubt, be explicit about the status you want

## Migration Guide

Existing code will continue to work without any changes:

```ruby
# This still works and defaults to active prompts
PromptEngine.render("my-prompt", { var1: "value1" })
```

To start using status filtering:

```ruby
# New code can specify status
PromptEngine.render("my-prompt", 
  { var1: "value1" },
  options: { status: "draft" }
)
```

## Error Handling

If a prompt doesn't exist with the specified status, an `ActiveRecord::RecordNotFound` error is raised:

```ruby
# If "welcome-email" exists but only as "active", not "draft"
PromptEngine.render("welcome-email", options: { status: "draft" })
# => ActiveRecord::RecordNotFound
```