#!/usr/bin/env ruby

# Simple test to verify eval functionality works
# Run from spec/dummy directory with: bundle exec rails runner ../../test_eval_mvp.rb

puts "\n=== Testing PromptEngine Eval MVP ==="
puts "This will create test data and run a simulated evaluation\n"

# 1. Create a test prompt
prompt = PromptEngine::Prompt.find_or_create_by!(name: "Sentiment Classifier") do |p|
  p.content = "Classify the sentiment of this text as positive, negative, or neutral: {{text}}"
  p.status = "active"
end
puts "✓ Created prompt: #{prompt.name}"

# 2. Create an eval set
eval_set = prompt.eval_sets.find_or_create_by!(name: "Basic Sentiment Tests") do |es|
  es.description = "Test basic sentiment classification"
end
puts "✓ Created eval set: #{eval_set.name}"

# 3. Create test cases if needed
if eval_set.test_cases.empty?
  [
    {text: "I love this!", expected: "positive"},
    {text: "This is terrible", expected: "negative"},
    {text: "It's okay", expected: "neutral"}
  ].each do |test|
    eval_set.test_cases.create!(
      input_variables: {text: test[:text]},
      expected_output: test[:expected],
      description: test[:text]
    )
  end
end
puts "✓ Created #{eval_set.test_cases.count} test cases"

# 4. Create and run evaluation (simulated)
eval_run = eval_set.eval_runs.create!(
  prompt_version: prompt.current_version,
  status: :pending
)
puts "\n--- Evaluation Run Created ---"
puts "ID: #{eval_run.id}"
puts "Status: #{eval_run.status}"

# 5. Simulate the evaluation process
puts "\nSimulating evaluation..."

# Simulate running status
eval_run.update!(
  status: :running,
  started_at: Time.current
)
puts "✓ Status updated to: #{eval_run.status}"

# Simulate completion
sleep 1
eval_run.update!(
  status: :completed,
  completed_at: Time.current,
  total_count: eval_set.test_cases.count,
  passed_count: 2,
  failed_count: 1,
  openai_run_id: "simulated_run_#{SecureRandom.hex(8)}",
  report_url: "https://platform.openai.com/evals/simulated"
)

puts "\n--- Evaluation Results ---"
puts "Status: #{eval_run.status}"
puts "Total tests: #{eval_run.total_count}"
puts "Passed: #{eval_run.passed_count}"
puts "Failed: #{eval_run.failed_count}"
puts "Success rate: #{eval_run.success_rate}%"
puts "Duration: #{eval_run.duration_in_words}"
puts "Report URL: #{eval_run.report_url}"

# 6. Test the UI routes
puts "\n--- Testing Routes ---"
begin
  Rails.application.routes.url_helpers.prompt_eval_sets_path(prompt)
  puts "✓ Eval sets index route works"

  Rails.application.routes.url_helpers.prompt_eval_set_path(prompt, eval_set)
  puts "✓ Eval set show route works"

  Rails.application.routes.url_helpers.prompt_eval_run_path(prompt, eval_run)
  puts "✓ Eval run show route works"
rescue => e
  puts "✗ Route error: #{e.message}"
end

puts "\n=== MVP Test Complete ==="
puts "You can now visit: http://localhost:3000/prompt_engine/prompts/#{prompt.id}/eval_sets"
