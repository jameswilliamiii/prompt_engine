#!/usr/bin/env ruby

# Test script to verify eval works with Settings API key
# Run from spec/dummy directory with: bundle exec rails runner ../../test_settings_api_key.rb

puts "\n=== Testing Eval with Settings API Key ==="

# 1. Check current Settings configuration
settings = PromptEngine::Setting.instance
puts "\nCurrent Settings:"
puts "OpenAI API key configured: #{settings.openai_configured?}"
puts "Masked key: #{settings.masked_openai_api_key}" if settings.openai_configured?

# 2. Test OpenAI client initialization
begin
  client = PromptEngine::OpenAiEvalsClient.new
  puts "✓ OpenAI client initialized successfully"
rescue PromptEngine::OpenAiEvalsClient::AuthenticationError => e
  puts "✗ OpenAI client failed: #{e.message}"
  puts "\nTo fix this:"
  puts "1. Go to Settings in the admin interface"
  puts "2. Add your OpenAI API key"
  puts "3. Save the settings"
  exit 1
end

# 3. Find or create test data
prompt = PromptEngine::Prompt.find_or_create_by!(name: "Test Sentiment") do |p|
  p.content = "Classify sentiment: {{text}}"
  p.status = "active"
end

eval_set = prompt.eval_sets.find_or_create_by!(name: "Quick Test") do |es|
  es.description = "Testing with Settings API key"
end

if eval_set.test_cases.empty?
  eval_set.test_cases.create!(
    input_variables: { text: "Great product!" },
    expected_output: "positive"
  )
end

puts "\n✓ Test data ready:"
puts "  Prompt: #{prompt.name}"
puts "  Eval set: #{eval_set.name}"
puts "  Test cases: #{eval_set.test_cases.count}"

# 4. Check if we can run evaluation
controller = PromptEngine::EvalSetsController.new
controller.instance_variable_set(:@prompt, prompt)
controller.instance_variable_set(:@eval_set, eval_set)

if controller.send(:api_key_configured?)
  puts "\n✓ API key is configured and ready for evaluation!"
  puts "\nYou can now:"
  puts "1. Visit http://localhost:3000/prompt_engine/prompts/#{prompt.id}/eval_sets/#{eval_set.id}"
  puts "2. Click 'Run Evaluation' to test with the Settings API key"
else
  puts "\n✗ API key not configured"
  puts "Please configure it in Settings first"
end
