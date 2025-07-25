namespace :prompt_engine do
  desc "Demo the evaluation workflow"
  task eval_demo: :environment do
    puts "\n=== ActivePrompt Evaluation Demo ==="
    puts "This demo will walk through the complete evaluation workflow\n\n"

    # Step 1: Create or find a prompt
    prompt = ActivePrompt::Prompt.find_or_create_by(name: "demo_summarizer") do |p|
      p.description = "Demo prompt for testing evaluations"
      p.content = "Summarize this in one word: {{text}}"
      p.system_message = "You are a concise summarizer. Always respond with exactly one word."
      p.model = "gpt-3.5-turbo"
      p.temperature = 0.0
      p.max_tokens = 10
      p.status = "active"
    end
    puts "✓ Created prompt: #{prompt.name}"

    # Step 2: Create an evaluation set
    eval_set = prompt.eval_sets.find_or_create_by(name: "Demo Eval Set") do |es|
      es.description = "Testing one-word summaries"
    end
    puts "✓ Created eval set: #{eval_set.name}"

    # Step 3: Create test cases
    test_cases_data = [
      {
        input: {"text" => "The cat is sleeping peacefully on the warm windowsill"},
        expected: "Cat",
        description: "Animal summary"
      },
      {
        input: {"text" => "It's raining heavily with thunder and lightning"},
        expected: "Storm",
        description: "Weather summary"
      },
      {
        input: {"text" => "The delicious pizza has cheese, pepperoni, and mushrooms"},
        expected: "Pizza",
        description: "Food summary"
      }
    ]

    test_cases_data.each do |tc_data|
      test_case = eval_set.test_cases.find_or_create_by(
        description: tc_data[:description]
      ) do |tc|
        tc.input_variables = tc_data[:input]
        tc.expected_output = tc_data[:expected]
      end
      puts "✓ Created test case: #{test_case.description}"
    end

    # Step 4: Run evaluation
    puts "\n--- Running Evaluation ---"

    begin
      # Check if API key is configured
      if Rails.application.credentials.dig(:openai, :api_key).blank?
        puts "⚠️  OpenAI API key not configured"
        puts "   To configure: rails credentials:edit"
        puts "   Add: openai:\\n  api_key: your-api-key"
        puts "\n--- Using Mock Evaluation ---"

        # Create a mock eval run
        eval_run = eval_set.eval_runs.create!(
          prompt_version: prompt.current_version
        )

        # Simulate evaluation
        eval_run.update!(
          status: "completed",
          started_at: 2.seconds.ago,
          completed_at: Time.current,
          total_count: 3,
          passed_count: 2,
          failed_count: 1,
          error_message: nil
        )

        puts "✓ Mock evaluation completed"
      else
        puts "✓ OpenAI API key found"

        # Create real eval run
        eval_run = eval_set.eval_runs.create!(
          prompt_version: prompt.current_version
        )

        # Note: The actual OpenAI Evals API may not be available
        # This will fall back to mock if not available
        begin
          ActivePrompt::EvaluationRunner.new(eval_run).execute
          puts "✓ Evaluation submitted to OpenAI"
        rescue ActivePrompt::OpenAIEvalsClient::NotFoundError => e
          puts "⚠️  OpenAI Evals API not available on this account"
          puts "   Using mock evaluation instead"

          eval_run.update!(
            status: "completed",
            started_at: 2.seconds.ago,
            completed_at: Time.current,
            total_count: 3,
            passed_count: 2,
            failed_count: 1
          )
        end
      end

      # Step 5: Display results
      puts "\n--- Evaluation Results ---"
      eval_run.reload
      puts "Status: #{eval_run.status}"
      puts "Total tests: #{eval_run.total_count}"
      puts "Passed: #{eval_run.passed_count}"
      puts "Failed: #{eval_run.failed_count}"

      if eval_run.total_count > 0
        success_rate = (eval_run.passed_count.to_f / eval_run.total_count * 100).round(1)
        puts "Success rate: #{success_rate}%"
      end

      if eval_run.error_message.present?
        puts "Error: #{eval_run.error_message}"
      end

      # URLs to access the UI
      puts "\n--- View in Browser ---"
      puts "Eval Set: http://localhost:3000/prompt_engine/prompts/#{prompt.id}/eval_sets/#{eval_set.id}"
      puts "Eval Run: http://localhost:3000/prompt_engine/prompts/#{prompt.id}/eval_runs/#{eval_run.id}"
    rescue => e
      puts "❌ Error: #{e.message}"
      puts e.backtrace.first(5).join("\n")
    end

    puts "\n=== Demo Complete ==="
  end

  desc "Clean up eval demo data"
  task clean_eval_demo: :environment do
    prompt = ActivePrompt::Prompt.find_by(name: "demo_summarizer")
    if prompt
      prompt.destroy
      puts "✓ Cleaned up demo data"
    else
      puts "No demo data to clean up"
    end
  end
end
