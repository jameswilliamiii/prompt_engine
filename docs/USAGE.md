# PromptEngine Usage Guide

## Basic Usage in Rails Models

PromptEngine provides a simple API for using prompts in your Rails application:

```ruby
# In any Rails model or service
class CustomerService
  def send_welcome_email(customer)
    # Retrieve and render a prompt with variables
    prompt_data = PromptEngine.render(:welcome_email,
      variables: {
        customer_name: customer.name,
        company_name: "Your Company"
      }
    )

    # Use the rendered prompt with your AI service
    response = OpenAI::Client.new.chat(
      model: prompt_data[:model],
      messages: [
        { role: "system", content: prompt_data[:system_message] },
        { role: "user", content: prompt_data[:content] }
      ],
      temperature: prompt_data[:temperature],
      max_tokens: prompt_data[:max_tokens]
    )

    # Process the AI response...
  end
end
```

## Creating Prompts

1. Access the admin interface at `/prompt_engine`
2. Click "New Prompt"
3. Fill in the prompt details:
   - **Name**: A unique identifier (e.g., "welcome_email")
   - **Content**: The prompt text with variables using `{{variable_name}}` syntax
   - **System Message**: Instructions for the AI model
   - **Model**: The AI model to use (e.g., "gpt-4", "claude-3")
   - **Temperature**: Controls randomness (0.0 to 1.0)
   - **Max Tokens**: Maximum response length
   - **Status**: Set to "active" to make it available

## Variable Interpolation

PromptEngine supports variable placeholders in your prompts:

```ruby
# Prompt content: "Generate a summary for {{article_title}} about {{topic}}"

PromptEngine.render(:article_summary,
  variables: {
    article_title: "Rails Best Practices",
    topic: "performance optimization"
  }
)
# Returns: "Generate a summary for Rails Best Practices about performance optimization"
```

## API Reference

### PromptEngine.render

```ruby
PromptEngine.render(prompt_name, variables: {})
```

**Parameters:**

- `prompt_name` (String/Symbol): The name of the prompt to render
- `variables` (Hash): Key-value pairs for variable interpolation

**Returns:** A hash containing:

- `:content` - The rendered prompt with variables interpolated
- `:system_message` - The system message with variables interpolated
- `:model` - The AI model specified
- `:temperature` - The temperature setting
- `:max_tokens` - The max tokens setting

**Raises:**

- `ActiveRecord::RecordNotFound` - If no active prompt exists with the given name

## Best Practices

1. **Use descriptive prompt names**: Choose names that clearly indicate the prompt's purpose
2. **Version control**: The "archived" status allows you to keep old versions while using new ones
3. **Test before deploying**: Use the admin interface to preview how prompts render
4. **Handle errors gracefully**: Always rescue `ActiveRecord::RecordNotFound` in production

## Example Integration

Here's a complete example of integrating PromptEngine with a support ticket system:

```ruby
class SupportTicket < ApplicationRecord
  def generate_ai_response
    prompt_data = PromptEngine.render(:support_response,
      variables: {
        customer_name: customer.name,
        issue_description: description,
        product_name: product.name
      }
    )

    # Call your AI service
    ai_response = AiService.generate(prompt_data)

    # Create a ticket response
    ticket_responses.create!(
      content: ai_response,
      generated_by_ai: true
    )
  rescue ActiveRecord::RecordNotFound
    # Fallback if prompt doesn't exist
    Rails.logger.error "Support response prompt not found"
    nil
  end
end
```
