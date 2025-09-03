module PromptEngine
  class WorkflowEngine
    def initialize(workflow)
      @workflow = workflow
    end

    def execute(initial_input: "", variables: {})
      original_input = initial_input
      previous_output = nil
      final_output = nil

      @workflow.steps.keys.sort.each_with_index do |step_key, index|
        # Strict rebuild per step. If pass_original_input is false we only propagate previous output.
        step_vars = if index == 0
          variables.dup
        elsif @workflow.pass_original_input
          variables.dup
        else
          {} # no original vars when disabled
        end

        step_vars[:input] = if index == 0
          initial_input
        elsif @workflow.pass_original_input
          original_input
        else
          previous_output
        end

        step_vars[:original_input] = original_input if index == 0 && @workflow.pass_original_input

        prompt_slug = @workflow.steps[step_key]
        rendered = PromptEngine.render(prompt_slug, **step_vars)
        final_output = rendered.content
        previous_output = final_output
      end

      final_output
    end

    def execute_with_steps(initial_input: "", variables: {}, provider: nil, api_key: nil, save_run: true)
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
          step_vars = if index == 0
            variables.dup
          elsif @workflow.pass_original_input
            variables.dup
          else
            {}
          end

          step_input = if index == 0
            initial_input
          elsif @workflow.pass_original_input
            original_input
          else
            previous_output
          end

          step_vars[:input] = step_input
          step_vars[:original_input] = original_input if index == 0 && @workflow.pass_original_input

          # Snapshot BEFORE execution (only what we want to expose)
          snapshot = if @workflow.pass_original_input
            allowed = variables.keys.map { |k| k.to_sym } + [ :input, :original_input ]
            step_vars.select { |k, _| allowed.include?(k.to_sym) }
          else
            { input: step_input }
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
            rendered = PromptEngine.render(prompt_slug, **step_vars)
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

          previous_output = output_content
        end

        results[:final_output] = previous_output
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
