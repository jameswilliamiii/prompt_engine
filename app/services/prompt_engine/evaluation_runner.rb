# Client is autoloaded by Rails

module PromptEngine
  class EvaluationRunner
    def initialize(eval_run)
      @eval_run = eval_run
      @eval_set = eval_run.eval_set
      @prompt_version = eval_run.prompt_version
      @prompt = @prompt_version.prompt
      @client = OpenAiEvalsClient.new
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
      
      # Build schema properties dynamically based on prompt parameters
      schema_properties = {}
      required_fields = []
      
      # Add properties for each parameter in the prompt
      @prompt.parameters.each do |param|
        schema_properties[param.name] = { type: parameter_type_to_json_schema(param.parameter_type) }
        required_fields << param.name if param.required?
      end
      
      # Always include expected_output
      schema_properties["expected_output"] = { type: "string" }
      required_fields << "expected_output"
      
      # Create eval configuration on OpenAI
      eval_config = @client.create_eval(
        name: "#{@prompt.name} - #{@eval_set.name}",
        data_source_config: {
          type: "custom",
          item_schema: {
            type: "object",
            properties: schema_properties,
            required: required_fields
          },
          include_sample_schema: true
        },
        testing_criteria: build_testing_criteria
      )
      
      @eval_set.update!(openai_eval_id: eval_config["id"])
    end
    
    def upload_test_data
      # Create temporary JSONL file
      file_path = Rails.root.join("tmp", "eval_#{@eval_run.id}.jsonl")
      
      File.open(file_path, "w") do |file|
        @eval_set.test_cases.each do |test_case|
          # Flatten the structure - put input variables directly on item
          item_data = test_case.input_variables.dup
          item_data["expected_output"] = test_case.expected_output
          
          line = { item: item_data }
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
      
      # Replace {{variable}} with {{ item.variable }} (flat structure)
      content.gsub(/\{\{(\w+)\}\}/) do |match|
        variable_name = $1
        "{{ item.#{variable_name} }}"
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
    
    def build_testing_criteria
      case @eval_set.grader_type
      when 'exact_match'
        [{
          type: "string_check",
          name: "Exact match",
          input: "{{ sample.output_text }}",
          operation: "eq",
          reference: "{{ item.expected_output }}"
        }]
      when 'regex'
        [{
          type: "string_check",
          name: "Regex match",
          input: "{{ sample.output_text }}",
          operation: "regex",
          reference: @eval_set.grader_config['pattern']
        }]
      when 'contains'
        [{
          type: "string_check", 
          name: "Contains text",
          input: "{{ sample.output_text }}",
          operation: "contains",
          reference: "{{ item.expected_output }}"
        }]
      when 'json_schema'
        # OpenAI doesn't support json_schema_check directly
        # For MVP, we'll just verify the output is valid JSON format
        # and matches the expected output exactly
        [{
          type: "string_check",
          name: "JSON format validation",
          input: "{{ sample.output_text }}",
          operation: "eq",
          reference: "{{ item.expected_output }}"
        }]
      else
        # Default to exact match
        [{
          type: "string_check",
          name: "Exact match",
          input: "{{ sample.output_text }}",
          operation: "eq",
          reference: "{{ item.expected_output }}"
        }]
      end
    end
    
    def parameter_type_to_json_schema(type)
      case type
      when "integer"
        "integer"
      when "decimal"
        "number"
      when "boolean"
        "boolean"
      when "array", "json"
        "array"
      else
        "string"
      end
    end
    
  end
end