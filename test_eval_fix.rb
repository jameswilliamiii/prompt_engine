#!/usr/bin/env ruby

# Test the fixed eval flow
# Run from spec/dummy directory with: bundle exec rails runner ../../test_eval_fix.rb

puts "\n=== Testing Fixed Eval Flow ==="

# Create a simple prompt for testing
prompt = ActivePrompt::Prompt.find_or_create_by!(name: "Email Classifier") do |p|
  p.content = "Classify this email about {{email_topic}} as 'urgent' or 'not urgent'"
  p.status = "active"
end

# Ensure parameters are synced
prompt.sync_parameters!

puts "✓ Prompt: #{prompt.name}"
puts "  Parameters: #{prompt.parameters.pluck(:name).join(', ')}"

# Create eval set
eval_set = prompt.eval_sets.find_or_create_by!(name: "Email Priority Test") do |es|
  es.description = "Test email classification"
end

# Clear any existing openai_eval_id to force recreation with new schema
eval_set.update!(openai_eval_id: nil) if eval_set.openai_eval_id.present?

# Create test case
if eval_set.test_cases.empty?
  eval_set.test_cases.create!(
    input_variables: { email_topic: "server outage" },
    expected_output: "urgent",
    description: "Server outage email"
  )
end

puts "✓ Eval set: #{eval_set.name} (#{eval_set.test_cases.count} test cases)"

# Test the data format
runner = ActivePrompt::EvaluationRunner.new(
  eval_set.eval_runs.build(prompt_version: prompt.current_version)
)

# Show what the flattened data will look like
test_case = eval_set.test_cases.first
item_data = test_case.input_variables.dup
item_data["expected_output"] = test_case.expected_output

puts "\n--- Test Data Format ---"
puts "Original: { input_variables: #{test_case.input_variables}, expected_output: '#{test_case.expected_output}' }"
puts "Flattened: { item: #{item_data} }"

# Show template conversion
content = prompt.content
converted = content.gsub(/\{\{(\w+)\}\}/) { |match| "{{ item.#{$1} }}" }

puts "\n--- Template Conversion ---"
puts "Original: #{content}"
puts "Converted: #{converted}"

puts "\n✓ Data format should now match OpenAI's expectations!"
puts "\nVisit http://localhost:3000/active_prompt/prompts/#{prompt.id}/eval_sets/#{eval_set.id}"
puts "to run the evaluation with the fixed format."