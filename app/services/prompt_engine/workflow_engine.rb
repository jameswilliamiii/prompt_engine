module PromptEngine
  class WorkflowEngine
    def initialize(workflow)
      @workflow = workflow
    end

  # Backward compatible: allow arbitrary variable keywords without explicit :variables hash
  def execute(initial_input: "", **variables)
      original_input = initial_input
      previous_output = nil
      final_output = nil

      @workflow.steps.keys.sort.each_with_index do |step_key, index|
        # Strict rebuild per step of baseline variables
        step_vars = if index.zero?
          variables.dup
        elsif @workflow.pass_original_input
          variables.dup
        else
          {}
        end

        # Merge previous step structured output (parsed JSON / Hash) into variables so
        # downstream prompts can reference keys directly (e.g. {{slug}})
        if index > 0 && previous_output
          parsed_prev = nil
          if previous_output.is_a?(Hash)
            parsed_prev = previous_output
          elsif previous_output.is_a?(String)
            begin
              parsed_prev = JSON.parse(previous_output)
            rescue JSON::ParserError
              parsed_prev = nil
            end
          end
          if parsed_prev.is_a?(Hash)
            parsed_prev.each do |k, v|
              # Don't clobber explicitly supplied vars
              step_vars[k.to_sym] = v unless step_vars.key?(k.to_sym)
            end
          end
          # Backward compatible convenience variables
          step_vars[:previous_output] = previous_output
          step_vars[:output] = previous_output.is_a?(Hash) ? previous_output.to_json : previous_output
        end

        # Determine the special :input variable for this step
        step_vars[:input] = if index.zero?
          initial_input
        elsif @workflow.pass_original_input
          original_input
        else
          # fall back to raw previous output text or JSON string
          previous_output.is_a?(Hash) ? previous_output.to_json : previous_output
        end

  # Only include original_input explicitly for first step when configured
  step_vars[:original_input] = original_input if index.zero? && @workflow.pass_original_input

        prompt_slug = @workflow.steps[step_key]
  rendered = PromptEngine.render(prompt_slug, step_vars)
        final_output = rendered.content

        # Attempt to parse JSON so subsequent step merging can use Hash
        if final_output.is_a?(String)
          begin
            previous_output = JSON.parse(final_output)
          rescue JSON::ParserError
            previous_output = final_output
          end
        else
          previous_output = final_output
        end
      end

      final_output
    end

  # Backward compatible: capture arbitrary variable keywords
  def execute_with_steps(initial_input: "", provider: nil, api_key: nil, save_run: true, **variables)
      original_input = initial_input
      previous_output = nil
  results = { steps: [], total_execution_time: 0 }
      start_time = Time.current
      workflow_run = nil

      if save_run
        workflow_run = @workflow.workflow_runs.create!(
          initial_input: initial_input,
          input_variables: variables,
          status: :completed,
          execution_time: 0
        )
      end

      begin
        @workflow.steps.keys.sort.each_with_index do |step_key, index|
          # Strict per-step variable construction
          step_vars = if index.zero?
            variables.dup
          elsif @workflow.pass_original_input
            variables.dup
          else
            {}
          end

          # Merge previous structured output (Hash or parseable JSON) into variables
          if index > 0 && previous_output
            parsed_prev = if previous_output.is_a?(Hash)
              previous_output
            elsif previous_output.is_a?(String)
              begin
                JSON.parse(previous_output)
              rescue JSON::ParserError
                nil
              end
            end
            if parsed_prev.is_a?(Hash)
              parsed_prev.each do |k, v|
                step_vars[k.to_sym] = v unless step_vars.key?(k.to_sym)
              end
            end
            step_vars[:previous_output] = previous_output
            step_vars[:output] = previous_output.is_a?(Hash) ? previous_output.to_json : previous_output
          end

          step_input = if index.zero?
            initial_input
          elsif @workflow.pass_original_input
            original_input
          else
            previous_output.is_a?(Hash) ? previous_output.to_json : previous_output
          end

          step_vars[:input] = step_input
          step_vars[:original_input] = original_input if index.zero? && @workflow.pass_original_input

          # Snapshot BEFORE execution (only what we want to expose)
          snapshot = if @workflow.pass_original_input
            allowed = variables.keys.map { |k| k.to_sym } + [ :input, :original_input ]
            # Also include carried-forward keys from parsed previous output that are not sensitive
            step_vars.select { |k, _| allowed.include?(k.to_sym) || (index > 0 && previous_output.is_a?(Hash) && previous_output.key?(k.to_s)) }
          else
            base = { input: step_input }
            if index > 0 && previous_output.is_a?(Hash)
              base.merge!(previous_output)
            end
            base
          end

          prompt_slug = @workflow.steps[step_key]
          step_start = Time.current
          output_content = nil
          exec_time_ms = 0

          if provider && api_key
            prompt = PromptEngine::Prompt.find_by(slug: prompt_slug)
            if prompt
              executor = PromptEngine::PlaygroundExecutor.new(
                prompt: prompt,
                provider: provider,
                api_key: api_key,
                parameters: step_vars
              )
              execution_result = executor.execute
              output_content = execution_result[:response]
              exec_time_ms = execution_result[:execution_time]
              # Attempt to parse JSON if json_mode enabled
              if prompt.respond_to?(:json_mode) && prompt.json_mode
                begin
                  parsed = JSON.parse(output_content)
                  output_content = parsed
                rescue JSON::ParserError
                  # leave original string; parsing failed
                end
              end
            else
              output_content = "Error: Prompt '#{prompt_slug}' not found"
              exec_time_ms = 0
            end
          else
            rendered = PromptEngine.render(prompt_slug, step_vars)
            output_content = rendered.content
            if rendered.respond_to?(:json_mode) && rendered.json_mode
              begin
                parsed = JSON.parse(output_content)
                output_content = parsed
              rescue JSON::ParserError
              end
            end
            exec_time_ms = (Time.current - step_start) * 1000
          end

          results[:steps] << {
            step: step_key,
            prompt_slug: prompt_slug,
            input: step_vars[:input],
            input_parameters: snapshot,
            output: output_content,
            execution_time: exec_time_ms
          }

          # Legacy flat keys for backward compatibility (e.g., "greeting_output")
          results["#{prompt_slug}_output"] = output_content

          # For chaining we keep raw output_content, but also a parsed Hash if possible
          previous_output = if output_content.is_a?(String)
            begin
              JSON.parse(output_content)
            rescue JSON::ParserError
              output_content
            end
          else
            output_content
          end
        end # each step

  results[:final_output] = previous_output
  # Legacy key expected by older specs
  results["result"] = previous_output
        results[:total_execution_time] = (Time.current - start_time) * 1000

        if workflow_run
          workflow_run.update!(
            results: results,
            execution_time: results[:total_execution_time] / 1000.0
          )
        end
        results
      rescue => e
        workflow_run&.update!(status: :failed, error_message: e.message) if workflow_run
        raise e
      end
    end
  end
end
