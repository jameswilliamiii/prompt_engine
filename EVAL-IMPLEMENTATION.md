# Evaluation System Implementation - Sprint 1 MVP

## Overview
Minimal viable evaluation system that integrates with OpenAI's Evals API to:
1. Create evaluation sets with test cases
2. Submit evaluations to OpenAI's infrastructure
3. Poll for and display results

## Key Design Decision: OpenAI Evals API Integration
Instead of building our own evaluation infrastructure, we'll leverage OpenAI's Evals API which provides:
- Robust evaluation execution infrastructure
- Built-in graders (starting with exact match)
- Consistent metrics and reporting
- Integration with OpenAI's ecosystem

## Sprint 1: Core MVP Implementation

### 1. Data Models (Simplified)

#### ActivePrompt::EvalSet
```ruby
# app/models/active_prompt/eval_set.rb
class ActivePrompt::EvalSet < ApplicationRecord
  belongs_to :prompt
  has_many :test_cases, dependent: :destroy
  has_many :eval_runs, dependent: :destroy
  
  validates :name, presence: true
  
  # Simple fields:
  # - name: string
  # - description: text
  # - prompt_id: integer
end
```

#### ActivePrompt::TestCase
```ruby
# app/models/active_prompt/test_case.rb
class ActivePrompt::TestCase < ApplicationRecord
  belongs_to :eval_set
  has_many :eval_results, dependent: :destroy
  
  validates :input_variables, presence: true
  validates :expected_output, presence: true
  
  # Simple fields:
  # - eval_set_id: integer
  # - input_variables: json (hash of variables for prompt)
  # - expected_output: text
  # - description: text (optional)
end
```

#### ActivePrompt::EvalRun
```ruby
# app/models/active_prompt/eval_run.rb
class ActivePrompt::EvalRun < ApplicationRecord
  belongs_to :eval_set
  belongs_to :prompt_version
  has_many :eval_results, dependent: :destroy
  
  enum status: { pending: 0, running: 1, completed: 2, failed: 3 }
  
  # Simple fields:
  # - eval_set_id: integer
  # - prompt_version_id: integer
  # - status: integer
  # - started_at: datetime
  # - completed_at: datetime
  # - total_count: integer
  # - passed_count: integer
  # - failed_count: integer
end
```

#### ActivePrompt::EvalResult
```ruby
# app/models/active_prompt/eval_result.rb
class ActivePrompt::EvalResult < ApplicationRecord
  belongs_to :eval_run
  belongs_to :test_case
  
  # Simple fields:
  # - eval_run_id: integer
  # - test_case_id: integer
  # - actual_output: text
  # - passed: boolean
  # - execution_time_ms: integer
  # - error_message: text (if failed)
end
```

### 2. Migrations

```ruby
# db/migrate/xxx_create_eval_tables.rb
class CreateEvalTables < ActiveRecord::Migration[7.1]
  def change
    create_table :active_prompt_eval_sets do |t|
      t.string :name, null: false
      t.text :description
      t.references :prompt, null: false, foreign_key: { to_table: :active_prompt_prompts }
      t.timestamps
    end
    
    create_table :active_prompt_test_cases do |t|
      t.references :eval_set, null: false, foreign_key: { to_table: :active_prompt_eval_sets }
      t.json :input_variables, null: false, default: {}
      t.text :expected_output, null: false
      t.text :description
      t.timestamps
    end
    
    create_table :active_prompt_eval_runs do |t|
      t.references :eval_set, null: false, foreign_key: { to_table: :active_prompt_eval_sets }
      t.references :prompt_version, null: false, foreign_key: { to_table: :active_prompt_prompt_versions }
      t.integer :status, default: 0, null: false
      t.datetime :started_at
      t.datetime :completed_at
      t.integer :total_count, default: 0
      t.integer :passed_count, default: 0
      t.integer :failed_count, default: 0
      t.text :error_message
      t.timestamps
    end
    
    create_table :active_prompt_eval_results do |t|
      t.references :eval_run, null: false, foreign_key: { to_table: :active_prompt_eval_runs }
      t.references :test_case, null: false, foreign_key: { to_table: :active_prompt_test_cases }
      t.text :actual_output
      t.boolean :passed, default: false
      t.integer :execution_time_ms
      t.text :error_message
      t.timestamps
    end
    
    add_index :active_prompt_eval_sets, [:prompt_id, :name], unique: true
  end
end
```

### 3. OpenAI Evals API Client

Since RubyLLM doesn't support the Evals API, we need a simple client:

```ruby
# app/clients/active_prompt/openai_evals_client.rb
module ActivePrompt
  class OpenAIEvalsClient
    BASE_URL = "https://api.openai.com/v1"
    
    def initialize(api_key: nil)
      @api_key = api_key || Rails.application.credentials.openai[:api_key]
    end
    
    def create_eval(name:, data_source_config:, testing_criteria:)
      post("/evals", {
        name: name,
        data_source_config: data_source_config,
        testing_criteria: testing_criteria
      })
    end
    
    def create_run(eval_id:, name:, data_source:)
      post("/evals/#{eval_id}/runs", {
        name: name,
        data_source: data_source
      })
    end
    
    def get_run(eval_id:, run_id:)
      get("/evals/#{eval_id}/runs/#{run_id}")
    end
    
    def upload_file(file_path, purpose: "evals")
      uri = URI("#{BASE_URL}/files")
      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{@api_key}"
      
      form_data = [
        ['purpose', purpose],
        ['file', File.open(file_path)]
      ]
      request.set_form(form_data, 'multipart/form-data')
      
      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(request)
      end
      
      JSON.parse(response.body)
    end
    
    private
    
    def post(path, body)
      uri = URI("#{BASE_URL}#{path}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      
      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{@api_key}"
      request["Content-Type"] = "application/json"
      request.body = body.to_json
      
      response = http.request(request)
      JSON.parse(response.body)
    end
    
    def get(path)
      uri = URI("#{BASE_URL}#{path}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      
      request = Net::HTTP::Get.new(uri)
      request["Authorization"] = "Bearer #{@api_key}"
      
      response = http.request(request)
      JSON.parse(response.body)
    end
  end
end
```

### 4. Updated Models with OpenAI Integration

Add fields to track OpenAI eval IDs:

```ruby
# Additional migrations needed:
class AddOpenAIFieldsToEvals < ActiveRecord::Migration[7.1]
  def change
    add_column :active_prompt_eval_sets, :openai_eval_id, :string
    add_column :active_prompt_eval_runs, :openai_run_id, :string
    add_column :active_prompt_eval_runs, :openai_file_id, :string
    add_column :active_prompt_eval_runs, :report_url, :string
    
    add_index :active_prompt_eval_sets, :openai_eval_id
    add_index :active_prompt_eval_runs, :openai_run_id
  end
end
```

### 5. Evaluation Runner with OpenAI Integration

```ruby
# app/services/active_prompt/evaluation_runner.rb
module ActivePrompt
  class EvaluationRunner
    def initialize(eval_run)
      @eval_run = eval_run
      @eval_set = eval_run.eval_set
      @prompt_version = eval_run.prompt_version
      @prompt = @prompt_version.prompt
      @client = OpenAIEvalsClient.new
    end
    
    def execute
      @eval_run.update!(status: :running, started_at: Time.current)
      
      # Step 1: Create or get OpenAI eval configuration
      ensure_openai_eval_exists
      
      # Step 2: Create test data file in JSONL format
      file_id = upload_test_data
      @eval_run.update!(openai_file_id: file_id)
      
      # Step 3: Create eval run on OpenAI
      openai_run = create_openai_run(file_id)
      @eval_run.update!(
        openai_run_id: openai_run["id"],
        report_url: openai_run["report_url"]
      )
      
      # Step 4: Poll for results
      poll_for_results
      
    rescue => e
      @eval_run.update!(status: :failed, error_message: e.message)
      raise
    end
    
    private
    
    def ensure_openai_eval_exists
      return if @eval_set.openai_eval_id.present?
      
      # Create eval configuration on OpenAI
      eval_config = @client.create_eval(
        name: "#{@prompt.name} - #{@eval_set.name}",
        data_source_config: {
          type: "custom",
          item_schema: {
            type: "object",
            properties: {
              input_variables: { type: "object" },
              expected_output: { type: "string" }
            },
            required: ["input_variables", "expected_output"]
          },
          include_sample_schema: true
        },
        testing_criteria: [
          {
            type: "string_check",
            name: "Exact match",
            input: "{{ sample.output_text }}",
            operation: "eq",
            reference: "{{ item.expected_output }}"
          }
        ]
      )
      
      @eval_set.update!(openai_eval_id: eval_config["id"])
    end
    
    def upload_test_data
      # Create temporary JSONL file
      file_path = Rails.root.join("tmp", "eval_#{@eval_run.id}.jsonl")
      
      File.open(file_path, "w") do |file|
        @eval_set.test_cases.each do |test_case|
          line = {
            item: {
              input_variables: test_case.input_variables,
              expected_output: test_case.expected_output
            }
          }
          file.puts(line.to_json)
        end
      end
      
      # Upload to OpenAI
      response = @client.upload_file(file_path)
      
      # Clean up
      File.delete(file_path)
      
      response["id"]
    end
    
    def create_openai_run(file_id)
      # Build message template with prompt content
      messages_template = [
        {
          role: "system",
          content: @prompt_version.system_message || ""
        },
        {
          role: "user", 
          content: build_templated_content
        }
      ]
      
      @client.create_run(
        eval_id: @eval_set.openai_eval_id,
        name: "Run at #{Time.current}",
        data_source: {
          type: "completions",
          model: @prompt_version.model || "gpt-4",
          input_messages: {
            type: "template",
            template: messages_template
          },
          source: { 
            type: "file_id", 
            id: file_id 
          }
        }
      )
    end
    
    def build_templated_content
      # Convert our {{variable}} syntax to OpenAI's template syntax
      content = @prompt_version.content.dup
      
      # Replace {{variable}} with {{ item.input_variables.variable }}
      content.gsub(/\{\{(\w+)\}\}/) do |match|
        variable_name = $1
        "{{ item.input_variables.#{variable_name} }}"
      end
    end
    
    def poll_for_results
      max_attempts = 60  # 5 minutes with 5 second intervals
      attempts = 0
      
      loop do
        attempts += 1
        
        run_status = @client.get_run(
          eval_id: @eval_set.openai_eval_id,
          run_id: @eval_run.openai_run_id
        )
        
        case run_status["status"]
        when "completed"
          process_results(run_status)
          break
        when "failed", "canceled"
          @eval_run.update!(
            status: :failed,
            error_message: run_status["error"] || "Eval run #{run_status["status"]}"
          )
          break
        else
          # Still running
          if attempts >= max_attempts
            @eval_run.update!(
              status: :failed,
              error_message: "Timeout waiting for eval results"
            )
            break
          end
          
          sleep 5
        end
      end
    end
    
    def process_results(run_status)
      # Extract counts from OpenAI response
      result_counts = run_status["result_counts"] || {}
      
      @eval_run.update!(
        status: :completed,
        completed_at: Time.current,
        total_count: result_counts["total"] || 0,
        passed_count: result_counts["passed"] || 0,
        failed_count: result_counts["failed"] || 0
      )
      
      # Note: Individual test results would need to be fetched separately
      # For MVP, we just store the aggregate counts
    end
  end
end
```

### 6. Controllers

#### EvalSetsController
```ruby
# app/controllers/active_prompt/eval_sets_controller.rb
module ActivePrompt
  class EvalSetsController < ApplicationController
    before_action :set_prompt
    before_action :set_eval_set, only: [:show, :edit, :update, :destroy, :run]
    
    def index
      @eval_sets = @prompt.eval_sets
    end
    
    def show
      @test_cases = @eval_set.test_cases
      @recent_runs = @eval_set.eval_runs.order(created_at: :desc).limit(5)
    end
    
    def new
      @eval_set = @prompt.eval_sets.build
    end
    
    def create
      @eval_set = @prompt.eval_sets.build(eval_set_params)
      
      if @eval_set.save
        redirect_to prompt_eval_set_path(@prompt, @eval_set)
      else
        render :new
      end
    end
    
    def run
      # Create new eval run with current prompt version
      @eval_run = @eval_set.eval_runs.create!(
        prompt_version: @prompt.current_version
      )
      
      # Run evaluation synchronously for MVP
      EvaluationRunner.new(@eval_run).execute
      
      redirect_to prompt_eval_run_path(@prompt, @eval_run)
    end
    
    private
    
    def set_prompt
      @prompt = Prompt.find(params[:prompt_id])
    end
    
    def set_eval_set
      @eval_set = @prompt.eval_sets.find(params[:id])
    end
    
    def eval_set_params
      params.require(:eval_set).permit(:name, :description)
    end
  end
end
```

#### TestCasesController
```ruby
# app/controllers/active_prompt/test_cases_controller.rb
module ActivePrompt
  class TestCasesController < ApplicationController
    before_action :set_prompt
    before_action :set_eval_set
    before_action :set_test_case, only: [:edit, :update, :destroy]
    
    def new
      @test_case = @eval_set.test_cases.build
      # Pre-populate with prompt's parameters
      @test_case.input_variables = @prompt.parameters.each_with_object({}) do |param, hash|
        hash[param.name] = param.default_value
      end
    end
    
    def create
      @test_case = @eval_set.test_cases.build(test_case_params)
      
      if @test_case.save
        redirect_to prompt_eval_set_path(@prompt, @eval_set)
      else
        render :new
      end
    end
    
    def edit
    end
    
    def update
      if @test_case.update(test_case_params)
        redirect_to prompt_eval_set_path(@prompt, @eval_set)
      else
        render :edit
      end
    end
    
    def destroy
      @test_case.destroy
      redirect_to prompt_eval_set_path(@prompt, @eval_set)
    end
    
    private
    
    def set_prompt
      @prompt = Prompt.find(params[:prompt_id])
    end
    
    def set_eval_set
      @eval_set = @prompt.eval_sets.find(params[:eval_set_id])
    end
    
    def set_test_case
      @test_case = @eval_set.test_cases.find(params[:id])
    end
    
    def test_case_params
      params.require(:test_case).permit(:description, :expected_output, input_variables: {})
    end
  end
end
```

#### EvalRunsController
```ruby
# app/controllers/active_prompt/eval_runs_controller.rb
module ActivePrompt
  class EvalRunsController < ApplicationController
    before_action :set_prompt
    before_action :set_eval_run
    
    def show
      # Note: Individual eval results are not fetched in MVP
      # Only aggregate counts from OpenAI are displayed
    end
    
    private
    
    def set_prompt
      @prompt = Prompt.find(params[:prompt_id])
    end
    
    def set_eval_run
      @eval_run = EvalRun.find(params[:id])
    end
  end
end
```

### 7. Routes

```ruby
# config/routes.rb
namespace :active_prompt do
  resources :prompts do
    resources :eval_sets do
      member do
        post :run
      end
      resources :test_cases, except: [:index, :show]
    end
    resources :eval_runs, only: [:show]
  end
end
```

### 8. Views

#### eval_sets/index.html.erb
```erb
<div class="page-header">
  <h1 class="page-header__title">Evaluation Sets for <%= @prompt.name %></h1>
  <%= link_to "New Evaluation Set", new_prompt_eval_set_path(@prompt), class: "button button--primary" %>
</div>

<div class="table-container">
  <table class="table">
    <thead>
      <tr>
        <th>Name</th>
        <th>Test Cases</th>
        <th>Last Run</th>
        <th>Actions</th>
      </tr>
    </thead>
    <tbody>
      <% @eval_sets.each do |eval_set| %>
        <tr>
          <td><%= link_to eval_set.name, prompt_eval_set_path(@prompt, eval_set) %></td>
          <td><%= eval_set.test_cases.count %></td>
          <td>
            <% if eval_set.eval_runs.any? %>
              <%= time_ago_in_words(eval_set.eval_runs.last.created_at) %> ago
            <% else %>
              Never
            <% end %>
          </td>
          <td>
            <%= link_to "View", prompt_eval_set_path(@prompt, eval_set), class: "button button--small" %>
          </td>
        </tr>
      <% end %>
    </tbody>
  </table>
</div>
```

#### eval_sets/show.html.erb
```erb
<div class="page-header">
  <h1 class="page-header__title"><%= @eval_set.name %></h1>
  <div class="page-header__actions">
    <%= link_to "Add Test Case", new_prompt_eval_set_test_case_path(@prompt, @eval_set), 
        class: "button button--secondary" %>
    <%= button_to "Run Evaluation", run_prompt_eval_set_path(@prompt, @eval_set), 
        method: :post, class: "button button--primary" %>
  </div>
</div>

<div class="card">
  <div class="card__header">
    <h2 class="card__title">Test Cases</h2>
  </div>
  <div class="card__content">
    <table class="table">
      <thead>
        <tr>
          <th>Description</th>
          <th>Input Variables</th>
          <th>Expected Output</th>
          <th>Actions</th>
        </tr>
      </thead>
      <tbody>
        <% @test_cases.each do |test_case| %>
          <tr>
            <td><%= test_case.description || "Test case ##{test_case.id}" %></td>
            <td>
              <code class="code-inline">
                <%= test_case.input_variables.to_json %>
              </code>
            </td>
            <td>
              <code class="code-inline">
                <%= truncate(test_case.expected_output, length: 50) %>
              </code>
            </td>
            <td>
              <%= link_to "Edit", edit_prompt_eval_set_test_case_path(@prompt, @eval_set, test_case), 
                  class: "button button--small" %>
              <%= link_to "Delete", prompt_eval_set_test_case_path(@prompt, @eval_set, test_case), 
                  method: :delete, data: { confirm: "Are you sure?" }, 
                  class: "button button--small button--danger" %>
            </td>
          </tr>
        <% end %>
      </tbody>
    </table>
  </div>
</div>

<div class="card">
  <div class="card__header">
    <h2 class="card__title">Recent Runs</h2>
  </div>
  <div class="card__content">
    <% if @recent_runs.any? %>
      <table class="table">
        <thead>
          <tr>
            <th>Version</th>
            <th>Status</th>
            <th>Results</th>
            <th>Run Time</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          <% @recent_runs.each do |run| %>
            <tr>
              <td>v<%= run.prompt_version.version %></td>
              <td>
                <span class="badge badge--<%= run.status %>">
                  <%= run.status.humanize %>
                </span>
              </td>
              <td>
                <%= run.passed_count %> / <%= run.total_count %> passed
              </td>
              <td><%= time_ago_in_words(run.created_at) %> ago</td>
              <td>
                <%= link_to "View Results", prompt_eval_run_path(@prompt, run), 
                    class: "button button--small" %>
              </td>
            </tr>
          <% end %>
        </tbody>
      </table>
    <% else %>
      <p>No evaluation runs yet.</p>
    <% end %>
  </div>
</div>
```

#### eval_runs/show.html.erb
```erb
<div class="page-header">
  <h1 class="page-header__title">Evaluation Run Results</h1>
  <%= link_to "Back to Eval Set", prompt_eval_set_path(@prompt, @eval_run.eval_set), 
      class: "button button--secondary" %>
</div>

<div class="card">
  <div class="card__header">
    <h2 class="card__title">Summary</h2>
  </div>
  <div class="card__content">
    <dl class="stats">
      <div class="stat">
        <dt>Status</dt>
        <dd>
          <span class="badge badge--<%= @eval_run.status %>">
            <%= @eval_run.status.humanize %>
          </span>
        </dd>
      </div>
      <div class="stat">
        <dt>Prompt Version</dt>
        <dd>v<%= @eval_run.prompt_version.version %></dd>
      </div>
      <div class="stat">
        <dt>Total Tests</dt>
        <dd><%= @eval_run.total_count %></dd>
      </div>
      <div class="stat">
        <dt>Passed</dt>
        <dd class="text-success"><%= @eval_run.passed_count %></dd>
      </div>
      <div class="stat">
        <dt>Failed</dt>
        <dd class="text-danger"><%= @eval_run.failed_count %></dd>
      </div>
      <div class="stat">
        <dt>Success Rate</dt>
        <dd>
          <%= number_to_percentage((@eval_run.passed_count.to_f / @eval_run.total_count * 100), 
              precision: 1) %>
        </dd>
      </div>
    </dl>
  </div>
</div>

<!-- Note: Individual test results are not available in the MVP. 
     OpenAI only returns aggregate counts. To see detailed results, 
     click "View OpenAI Report" above. -->
```

### 9. Updated Eval Runs View

Since we're using OpenAI's evaluation infrastructure, we need to update the eval runs view:

```erb
<!-- app/views/active_prompt/eval_runs/show.html.erb -->
<div class="page-header">
  <h1 class="page-header__title">Evaluation Run Results</h1>
  <div class="page-header__actions">
    <%= link_to "Back to Eval Set", prompt_eval_set_path(@prompt, @eval_run.eval_set), 
        class: "button button--secondary" %>
    <% if @eval_run.report_url.present? %>
      <%= link_to "View OpenAI Report", @eval_run.report_url, 
          target: "_blank", class: "button button--secondary" %>
    <% end %>
  </div>
</div>

<div class="card">
  <div class="card__header">
    <h2 class="card__title">Summary</h2>
  </div>
  <div class="card__content">
    <dl class="stats">
      <div class="stat">
        <dt>Status</dt>
        <dd>
          <span class="badge badge--<%= @eval_run.status %>">
            <%= @eval_run.status.humanize %>
          </span>
        </dd>
      </div>
      <div class="stat">
        <dt>Prompt Version</dt>
        <dd>v<%= @eval_run.prompt_version.version %></dd>
      </div>
      <div class="stat">
        <dt>Total Tests</dt>
        <dd><%= @eval_run.total_count %></dd>
      </div>
      <div class="stat">
        <dt>Passed</dt>
        <dd class="text-success"><%= @eval_run.passed_count %></dd>
      </div>
      <div class="stat">
        <dt>Failed</dt>
        <dd class="text-danger"><%= @eval_run.failed_count %></dd>
      </div>
      <div class="stat">
        <dt>Success Rate</dt>
        <dd>
          <% if @eval_run.total_count > 0 %>
            <%= number_to_percentage((@eval_run.passed_count.to_f / @eval_run.total_count * 100), 
                precision: 1) %>
          <% else %>
            N/A
          <% end %>
        </dd>
      </div>
    </dl>
  </div>
</div>

<% if @eval_run.status == 'running' %>
  <div class="card">
    <div class="card__content">
      <p>Evaluation is running on OpenAI's infrastructure. This page will refresh automatically.</p>
      <script>
        setTimeout(function() {
          location.reload();
        }, 5000);
      </script>
    </div>
  </div>
<% elsif @eval_run.status == 'failed' %>
  <div class="card">
    <div class="card__content">
      <p class="text-danger">Error: <%= @eval_run.error_message %></p>
    </div>
  </div>
<% end %>
```

### 10. Add Navigation Link

In `app/views/active_prompt/prompts/show.html.erb`, add a link to evaluations:

```erb
<%= link_to "Evaluations", prompt_eval_sets_path(@prompt), 
    class: "button button--secondary" %>
```

## Implementation Order

1. **Create both migrations (base tables + OpenAI fields) and run them**
2. **Create models with validations and associations**
3. **Implement OpenAIEvalsClient**
4. **Create controllers**
5. **Add routes**
6. **Create views**
7. **Implement EvaluationRunner with OpenAI integration**
8. **Add navigation link**
9. **Test end-to-end flow**

## Testing the MVP

1. Create a prompt with variables
2. Create an eval set for the prompt
3. Add test cases with different inputs and expected outputs
4. Run the evaluation
5. View results

## MVP Limitations & Considerations

### What's Included
- Integration with OpenAI's Evals API
- Exact match evaluation only (string_check grader)
- Synchronous polling for results (with auto-refresh UI)
- Aggregate pass/fail counts from OpenAI
- Link to OpenAI's detailed report

### What's NOT Included
- Individual test result details (would require additional API calls)
- Custom evaluator types beyond exact match
- Batch operations or import/export
- Progress tracking beyond status polling
- Local evaluation option (all evals run on OpenAI)

### API Key Requirements
- Requires OpenAI API key with access to Evals API
- Evals API may not be available on all OpenAI accounts
- Consider rate limits and costs

### Error Handling
- File upload failures
- Eval creation failures
- Polling timeouts
- API rate limits

## Future Enhancements (Not in Sprint 1)

- More grader types (regex, contains, LLM judge)
- Fetch individual test results from OpenAI
- Local evaluation option for simple checks
- Import/export test cases
- Comparison between runs
- Advanced metrics and visualizations
- Webhook integration for CI/CD
- Batch test case management