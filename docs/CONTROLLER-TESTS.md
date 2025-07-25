# Rails Controller Testing Best Practices

## Overview

This document outlines the best practices for testing controllers in the PromptEngine Rails engine.
Since Rails 5 and RSpec 3.5, the recommended approach has shifted from controller specs to request
specs, which test the full request/response cycle including routing, middleware, and views.

## Key Principle: Use Request Specs, Not Controller Specs

Rails and RSpec now recommend using request specs instead of controller specs because:

- Request specs test the full stack including routing and middleware
- Controller specs bypass critical parts of the application
- Performance improvements in Rails 5+ eliminated the speed advantage of controller specs
- Request specs provide more realistic integration testing

## Migration from Controller Specs to Request Specs

### Before (Controller Spec - Deprecated)

```ruby
# spec/controllers/prompts_controller_spec.rb
RSpec.describe PromptsController, type: :controller do
  describe "GET #index" do
    it "returns a success response" do
      get :index
      expect(response).to be_successful
    end
  end
end
```

### After (Request Spec - Recommended)

```ruby
# spec/requests/prompts_spec.rb
RSpec.describe "Prompts", type: :request do
  describe "GET /prompt_engine/prompts" do
    it "returns a success response" do
      get prompt_engine.prompts_path
      expect(response).to be_successful
    end
  end
end
```

## PromptEngine-Specific Testing Patterns

### 1. Engine Route Helpers

Since PromptEngine is a mountable engine, use the engine's route helpers:

```ruby
# Use engine route helpers
get prompt_engine.prompts_path
post prompt_engine.prompt_path(prompt)
patch prompt_engine.prompt_version_path(prompt, version)

# NOT plain paths
# get "/prompts"  # Wrong - doesn't include engine mount point
```

### 2. Testing CRUD Operations

#### Index Action

```ruby
describe "GET /prompt_engine/prompts" do
  let!(:draft_prompt) { create(:prompt, :draft) }
  let!(:prompt_engine) { create(:prompt, :active) }

  it "displays all prompts" do
    get prompt_engine.prompts_path

    expect(response).to be_successful
    expect(response.body).to include(draft_prompt.name)
    expect(response.body).to include(prompt_engine.name)
  end
end
```

#### Create Action

```ruby
describe "POST /prompt_engine/prompts" do
  context "with valid parameters" do
    let(:valid_attributes) do
      {
        name: "test_prompt",
        description: "Test description",
        content: "Hello {{name}}",
        status: "draft"
      }
    end

    it "creates a new prompt" do
      expect {
        post prompt_engine.prompts_path, params: { prompt: valid_attributes }
      }.to change(PromptEngine::Prompt, :count).by(1)

      expect(response).to redirect_to(prompt_engine.prompt_path(PromptEngine::Prompt.last))
      follow_redirect!
      expect(response.body).to include("Prompt was successfully created")
    end
  end

  context "with invalid parameters" do
    let(:invalid_attributes) do
      { name: "", content: "" }
    end

    it "does not create a new prompt" do
      expect {
        post prompt_engine.prompts_path, params: { prompt: invalid_attributes }
      }.not_to change(PromptEngine::Prompt, :count)

      expect(response).to be_unprocessable
    end
  end
end
```

#### Update Action

```ruby
describe "PATCH /prompt_engine/prompts/:id" do
  let(:prompt) { create(:prompt) }

  context "with valid parameters" do
    let(:new_attributes) do
      { name: "updated_name", content: "Updated content" }
    end

    it "updates the prompt" do
      patch prompt_engine.prompt_path(prompt), params: { prompt: new_attributes }

      prompt.reload
      expect(prompt.name).to eq("updated_name")
      expect(prompt.content).to eq("Updated content")
      expect(response).to redirect_to(prompt_engine.prompt_path(prompt))
    end
  end
end
```

#### Destroy Action

```ruby
describe "DELETE /prompt_engine/prompts/:id" do
  let!(:prompt) { create(:prompt) }

  it "destroys the prompt" do
    expect {
      delete prompt_engine.prompt_path(prompt)
    }.to change(PromptEngine::Prompt, :count).by(-1)

    expect(response).to redirect_to(prompt_engine.prompts_path)
  end
end
```

### 3. Testing JSON Responses

For API endpoints or JSON format responses:

```ruby
# spec/support/request_helpers.rb
module RequestHelpers
  def json
    JSON.parse(response.body)
  end
end

RSpec.configure do |config|
  config.include RequestHelpers, type: :request
end

# In your spec
describe "GET /prompt_engine/prompts.json" do
  let!(:prompt) { create(:prompt) }

  it "returns prompts as JSON" do
    get prompt_engine.prompts_path, headers: { "Accept" => "application/json" }

    expect(response).to be_successful
    expect(response.content_type).to match(/application\/json/)
    expect(json.first["name"]).to eq(prompt.name)
  end
end
```

### 4. Testing the Playground Feature

```ruby
describe "Playground", type: :request do
  let(:prompt) { create(:prompt, content: "Hello {{name}}") }

  describe "GET /prompt_engine/prompts/:id/playground" do
    it "displays the playground interface" do
      get prompt_engine.prompt_playground_path(prompt)

      expect(response).to be_successful
      expect(response.body).to include("Test Your Prompt")
      expect(response.body).to include(prompt.content)
    end
  end

  describe "POST /prompt_engine/prompts/:id/playground/execute" do
    before do
      # Configure test API keys
      allow(PromptEngine).to receive(:anthropic_api_key).and_return("test-key")
    end

    it "executes the prompt with provided variables" do
      VCR.use_cassette("playground_execution") do
        post prompt_engine.prompt_playground_execute_path(prompt),
             params: {
               variables: { name: "World" },
               provider: "anthropic",
               model: "claude-3-5-sonnet"
             }

        expect(response).to be_successful
        expect(json["success"]).to be true
        expect(json["result"]).to be_present
      end
    end
  end
end
```

### 5. Testing Strong Parameters

Ensure only permitted parameters are processed:

```ruby
describe "parameter filtering" do
  it "permits only allowed attributes" do
    post prompt_engine.prompts_path, params: {
      prompt: {
        name: "test",
        content: "content",
        admin_flag: true,  # Should be filtered
        secret_key: "hack" # Should be filtered
      }
    }

    created_prompt = PromptEngine::Prompt.last
    expect(created_prompt.attributes).not_to include("admin_flag", "secret_key")
  end
end
```

### 6. Shared Examples for Common Behaviors

```ruby
# spec/support/shared_examples/requires_prompt.rb
RSpec.shared_examples "requires existing prompt" do
  context "when prompt does not exist" do
    it "returns 404" do
      make_request(999999)
      expect(response).to have_http_status(:not_found)
    end
  end
end

# Usage
describe "GET /prompt_engine/prompts/:id" do
  let(:make_request) { |id| get prompt_engine.prompt_path(id) }

  it_behaves_like "requires existing prompt"

  context "when prompt exists" do
    let(:prompt) { create(:prompt) }

    it "displays the prompt" do
      make_request(prompt.id)
      expect(response).to be_successful
    end
  end
end
```

### 7. Testing Flash Messages

```ruby
describe "flash notifications" do
  it "displays success message after creation" do
    post prompt_engine.prompts_path, params: {
      prompt: attributes_for(:prompt)
    }

    follow_redirect!
    expect(response.body).to include("Prompt was successfully created")
  end

  it "displays error message on failure" do
    post prompt_engine.prompts_path, params: {
      prompt: { name: "" }
    }

    expect(response.body).to include("error")
  end
end
```

### 8. Testing Version Control Features

```ruby
describe "Version management" do
  let(:prompt) { create(:prompt) }
  let!(:version) { create(:prompt_version, prompt: prompt) }

  describe "GET /prompt_engine/prompts/:id/versions" do
    it "lists all versions" do
      get prompt_engine.prompt_versions_path(prompt)

      expect(response).to be_successful
      expect(response.body).to include("Version #{version.version_number}")
    end
  end

  describe "POST /prompt_engine/prompts/:id/versions/:version_id/restore" do
    it "restores a previous version" do
      post prompt_engine.restore_prompt_version_path(prompt, version)

      expect(response).to redirect_to(prompt_engine.prompt_path(prompt))
      prompt.reload
      expect(prompt.content).to eq(version.content)
    end
  end
end
```

## Best Practices Summary

1. **Always use request specs** for testing controllers in modern Rails
2. **Use engine route helpers** for all path generation
3. **Test the full request/response cycle** including redirects
4. **Verify both successful and failure scenarios**
5. **Use factories** for test data generation
6. **Extract common patterns** into shared examples
7. **Test response formats** (HTML, JSON) when applicable
8. **Use VCR** for external API calls
9. **Follow the AAA pattern**: Arrange, Act, Assert
10. **Keep tests focused** on behavior, not implementation

## Running Tests

```bash
# Run all request specs
bundle exec rspec spec/requests

# Run specific file
bundle exec rspec spec/requests/prompts_spec.rb

# Run with coverage report
bundle exec rspec

# View coverage
open coverage/index.html
```

## Common Anti-Patterns to Avoid

1. **Don't use controller specs** - they're deprecated
2. **Don't test Rails framework behavior** - trust that Rails works
3. **Don't stub the subject under test** - test real behavior
4. **Don't over-mock** - use real objects when possible
5. **Don't test private methods** - test through public interface
6. **Don't write brittle tests** that break with minor UI changes

## References

- [Rails Testing Guide](https://guides.rubyonrails.org/testing.html)
- [RSpec Rails Documentation](https://rspec.info/features/6-0/rspec-rails/)
- [Everyday Rails Testing with RSpec](https://leanpub.com/everydayrailsrspec)
- [Better Specs](https://www.betterspecs.org/)
