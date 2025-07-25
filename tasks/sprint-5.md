# Sprint 5: Testing Playground

## Sprint Goal

Create an interactive prompt testing environment where users can safely experiment with prompts,
test with real AI services, and analyze responses before deploying to production.

## Tasks

### 1. Build Playground UI Interface (Priority: High)

- [ ] Create playground controller and routes
- [ ] Design split-panel layout
- [ ] Add parameter input section
- [ ] Build response display area
- [ ] Include execution controls

### 2. Integrate AI Service Connections (Priority: High)

- [ ] Add OpenAI client configuration
- [ ] Add Anthropic client configuration
- [ ] Create service abstraction layer
- [ ] Handle API credentials securely
- [ ] Implement service selection

### 3. Implement Real-time Execution (Priority: High)

- [ ] Build prompt rendering pipeline
- [ ] Add parameter substitution
- [ ] Create API request handling
- [ ] Implement error handling
- [ ] Add timeout management

### 4. Add Response Display Features (Priority: High)

- [ ] Create response formatting
- [ ] Add syntax highlighting
- [ ] Implement response streaming
- [ ] Show token usage and costs
- [ ] Display response metadata

### 5. Create Test History System (Priority: Medium)

- [ ] Store test executions
- [ ] Build history browser
- [ ] Add test replay functionality
- [ ] Enable test comparison
- [ ] Implement test bookmarking

## Success Criteria

- Can test any prompt with custom parameters
- Real AI responses are displayed
- Response streaming works smoothly
- Token usage and costs are visible
- Test history aids in iteration
- Error handling is comprehensive

## MVP Implementation Plan

### Overview

The Testing Playground MVP will be a simple interface accessible from individual prompt pages that
allows users to test prompts with Anthropic Claude 3.5 Sonnet or OpenAI GPT-4o. Users enter their
API key each time, fill in parameters, submit the form, and see the response on a results page.

### Architecture Design

#### 1. Entry Point & UX Flow

- Add "Try this Prompt" button on the prompt show page
  (`app/views/prompt_engine/prompts/show.html.erb`)
- Opens playground at route: `/prompt_engine/prompts/:prompt_id/playground`
- Simple form layout:
  - Model selection dropdown (Anthropic Claude 3.5 Sonnet or OpenAI GPT-4o)
  - API key input field
  - Dynamic parameter inputs based on prompt template
  - Submit button
- After submission, redirect to results page showing the response

#### 2. RubyLLM Integration Strategy

```ruby
# app/services/prompt_engine/playground_executor.rb
class PromptEngine::PlaygroundExecutor
  def initialize(prompt:, provider:, api_key:, parameters:)
    @client = case provider
    when 'anthropic'
      RubyLLM::Anthropic.new(api_key: api_key)
    when 'openai'
      RubyLLM::OpenAI.new(api_key: api_key)
    end
  end

  def execute
    # Render prompt with parameters
    # Make API call
    # Return response
  end
end
```

**Key Design Decisions:**

- Use RubyLLM as a dependency of the engine
- No API key persistence - enter fresh each time
- Simple synchronous execution
- Direct instantiation of RubyLLM clients

#### 3. Parameter Detection & Input Generation

```ruby
# app/models/prompt_engine/parameter_parser.rb
class PromptEngine::ParameterParser
  def self.extract_parameters(prompt_content)
    # Extract {{variable_name}} patterns
    # Return array of parameter names
    prompt_content.scan(/\{\{(\w+)\}\}/).map(&:first).uniq
  end
end
```

**Features:**

- Auto-detect `{{variable}}` patterns in prompts
- Generate simple text inputs for each parameter
- Basic validation that all parameters are filled

#### 4. Controller & Routes Structure

```ruby
# config/routes.rb
resources :prompts do
  member do
    get 'playground'
    post 'playground', action: :execute, as: :playground_execute
  end
end

# app/controllers/prompt_engine/playground_controller.rb
class PromptEngine::PlaygroundController < ApplicationController
  def playground
    @prompt = Prompt.find(params[:id])
    @parameters = ParameterParser.extract_parameters(@prompt.content)
  end

  def execute
    @prompt = Prompt.find(params[:id])
    executor = PlaygroundExecutor.new(
      prompt: @prompt,
      provider: params[:provider],
      api_key: params[:api_key],
      parameters: params[:parameters]
    )

    begin
      @response = executor.execute
      @execution_time = executor.execution_time
      @token_count = executor.token_count
    rescue => e
      @error = e.message
    end

    render :result
  end
end
```

#### 5. Response Display

- Simple response page showing:
  - The rendered prompt (with parameters filled in)
  - The AI response (with basic formatting)
  - Execution time
  - Token count
  - Error message if failed
- "Try Again" button to go back to playground form

### Views Structure

```
app/views/prompt_engine/playground/
├── playground.html.erb    # Form with model selection, API key, parameters
└── result.html.erb        # Response display page
```

### Form Fields

```erb
<!-- playground.html.erb -->
<%= form_with url: playground_execute_prompt_path(@prompt), local: true do |f| %>
  <!-- Model Selection -->
  <%= f.select :provider, [
    ['Anthropic Claude 3.5 Sonnet', 'anthropic'],
    ['OpenAI GPT-4o', 'openai']
  ] %>

  <!-- API Key -->
  <%= f.password_field :api_key, placeholder: "Enter your API key", required: true %>

  <!-- Dynamic Parameters -->
  <% @parameters.each do |param| %>
    <%= f.text_field "parameters[#{param}]", placeholder: param, required: true %>
  <% end %>

  <%= f.submit "Test Prompt" %>
<% end %>
```

### Security & Error Handling

- API keys transmitted via POST only
- No API key logging or storage
- Basic error handling for:
  - Invalid API keys
  - Network errors
  - Rate limits
  - Missing parameters
- CSRF protection on form

### Dependencies to Add

```ruby
# prompt_engine.gemspec
spec.add_dependency "ruby-llm", "~> 0.1"  # Verify latest version
```

### No Database Changes Required

- No storage of executions in MVP
- No migrations needed

### CSS Additions

- Style the playground form using existing form styles
- Style the result page using existing card/content styles
- Add loading state for form submission

### Next Steps After MVP

Future enhancements could include:

- Response streaming
- Test history
- Cost estimation
- More providers
- Advanced parameter types
- API key session storage (optional)

### Implementation Decisions

1. **Model Configuration**: Hardcoded model versions

   - Anthropic: `claude-3-5-sonnet-20241022`
   - OpenAI: `gpt-4o`

2. **Prompt Rendering**: No preview - direct execution

3. **Response Formatting**: Plain text display in a `<pre>` tag

4. **Error Detail**: Basic user-friendly messages only

   - "Invalid API key"
   - "Network error - please try again"
   - "Rate limit exceeded"
   - "An error occurred"

5. **Loading State**: No loading state - synchronous form submission
