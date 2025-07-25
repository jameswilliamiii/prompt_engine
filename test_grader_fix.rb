#!/usr/bin/env ruby

# Test script to verify grader types work correctly
# Run from spec/dummy directory with: bundle exec rails runner ../../test_grader_fix.rb

puts "\n=== Testing Grader Types Fix ==="

# Find an eval set with json_schema grader type
json_eval = PromptEngine::EvalSet.where(grader_type: 'json_schema').first

if json_eval
  puts "\nFound JSON eval set: #{json_eval.name}"
  puts "Grader type: #{json_eval.grader_type} (#{json_eval.grader_type_display})"
  
  # Create a test evaluation runner
  eval_run = json_eval.eval_runs.build(
    prompt_version: json_eval.prompt.current_version
  )
  
  runner = PromptEngine::EvaluationRunner.new(eval_run)
  
  # Test the grader configuration
  criteria = runner.send(:build_testing_criteria)
  
  puts "\nTesting criteria generated:"
  puts criteria.inspect
  
  puts "\nExpected behavior:"
  puts "- Type should be 'string_check' (not 'json_schema_check')"
  puts "- Operation should be 'eq' for exact match"
  puts "- Should reference {{ item.expected_output }}"
  
  if criteria.first[:type] == 'string_check'
    puts "\n✅ Fix successful! Using supported 'string_check' grader type."
  else
    puts "\n❌ Still using unsupported grader type: #{criteria.first[:type]}"
  end
else
  puts "\nNo JSON schema eval sets found. Creating one for testing..."
  
  # Create a test prompt and eval set
  prompt = PromptEngine::Prompt.find_or_create_by!(name: "API Response Test") do |p|
    p.content = "Generate a JSON response for user: {{user_name}}"
    p.status = "active"
  end
  
  eval_set = prompt.eval_sets.create!(
    name: "JSON Response Test",
    grader_type: "json_schema",
    grader_config: {
      "schema" => {
        "type" => "object",
        "properties" => {
          "user" => { "type" => "string" }
        }
      }
    }
  )
  
  puts "Created test eval set with JSON grader"
  puts "Run this script again to test the fix"
end

puts "\nSupported OpenAI Evals grader types:"
puts "- string_check (with operations: eq, contains, regex)"
puts "- label_model (for LLM-based evaluation)"
puts "- text_similarity (for semantic similarity)"
puts "- score_model (for scoring outputs)"
puts "- python (for custom logic)"
puts "- endpoint (for external evaluation)"

puts "\nCurrent implementation:"
puts "- exact_match → string_check with eq operation ✓"
puts "- regex → string_check with regex operation ✓"
puts "- contains → string_check with contains operation ✓"
puts "- json_schema → string_check with eq operation (temporary) ✓"