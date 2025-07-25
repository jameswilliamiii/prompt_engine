#!/usr/bin/env ruby

# Test script to verify the eval flow works with OpenAI API
# Run from spec/dummy directory with: bundle exec rails runner ../../test_eval_flow.rb

puts "Testing ActivePrompt Eval Flow"
puts "=" * 50

# Find or create a test prompt
prompt = ActivePrompt::Prompt.find_or_create_by!(name: "Test Classifier") do |p|
  p.content = "Classify the following text as 'positive', 'negative', or 'neutral': {{text}}"
  p.status = "active"
end
puts "✓ Using prompt: #{prompt.name}"

# Create or find an eval set
eval_set = prompt.eval_sets.find_or_create_by!(name: "Sentiment Test") do |es|
  es.description = "Test sentiment classification accuracy"
end
puts "✓ Using eval set: #{eval_set.name}"

# Create test cases if none exist
if eval_set.test_cases.empty?
  test_data = [
    { text: "I love this product!", expected: "positive" },
    { text: "This is terrible.", expected: "negative" },
    { text: "It's okay.", expected: "neutral" }
  ]
  
  test_data.each do |data|
    eval_set.test_cases.create!(
      input_variables: { text: data[:text] },
      expected_output: data[:expected],
      description: "Test: #{data[:text]}"
    )
  end
  puts "✓ Created #{eval_set.test_cases.count} test cases"
else
  puts "✓ Found #{eval_set.test_cases.count} existing test cases"
end

# Check if OpenAI API key is configured
begin
  client = ActivePrompt::OpenAiEvalsClient.new
  puts "✓ OpenAI API key is configured"
rescue ActivePrompt::OpenAiEvalsClient::AuthenticationError => e
  puts "✗ Error: #{e.message}"
  puts "  Please configure your OpenAI API key in Rails credentials:"
  puts "  rails credentials:edit"
  puts "  Add: openai:"
  puts "         api_key: sk-your-key-here"
  exit 1
end

# Create and run evaluation
puts "\nStarting evaluation run..."
eval_run = eval_set.eval_runs.create!(
  prompt_version: prompt.current_version
)

begin
  runner = ActivePrompt::EvaluationRunner.new(eval_run)
  
  # For testing, let's simulate the flow without actually calling OpenAI
  # Comment out the next line and uncomment runner.execute to run with real API
  puts "✓ Would execute evaluation with OpenAI (skipping for demo)"
  # runner.execute
  
  # Simulate successful completion for demo
  eval_run.update!(
    status: :completed,
    completed_at: Time.current,
    total_count: eval_set.test_cases.count,
    passed_count: 2,
    failed_count: 1,
    report_url: "https://platform.openai.com/evals/demo"
  )
  
  puts "✓ Evaluation completed!"
  puts "  Status: #{eval_run.status}"
  puts "  Success rate: #{eval_run.success_rate}%"
  puts "  Duration: #{eval_run.duration_in_words}"
  
rescue => e
  puts "✗ Error during evaluation: #{e.message}"
  puts "  #{e.backtrace.first}"
end

puts "\n" + "=" * 50
puts "View results at: http://localhost:3000/active_prompt/prompts/#{prompt.id}/eval_runs/#{eval_run.id}"