#!/usr/bin/env ruby
# Simple test script to verify ActivePrompt.render works

require_relative 'spec/dummy/config/environment'

# Run migrations if needed
ActiveRecord::Migration.maintain_test_schema!

# Clear database
ActivePrompt::Prompt.destroy_all

# Create test prompts
welcome_prompt = ActivePrompt::Prompt.create!(
  name: "welcome_email",
  content: "Welcome {{customer_name}}! Thanks for joining {{product_name}}.",
  system_message: "You are a friendly assistant.",
  model: "gpt-4", 
  temperature: 0.7,
  max_tokens: 500,
  status: "active"
)

archived_prompt = ActivePrompt::Prompt.create!(
  name: "welcome_email",
  content: "Old version",
  status: "archived"
)

# Test 1: Basic rendering with variables
puts "Test 1: Basic rendering with variables"
result = ActivePrompt.render(:welcome_email, variables: {
  customer_name: "John Doe",
  product_name: "Premium Plan"
})

if result[:content] == "Welcome John Doe! Thanks for joining Premium Plan."
  puts "✅ PASS: Variables interpolated correctly"
else
  puts "❌ FAIL: Expected 'Welcome John Doe! Thanks for joining Premium Plan.', got '#{result[:content]}'"
end

# Test 2: Returns all prompt metadata
puts "\nTest 2: Returns all prompt metadata"
if result[:model] == "gpt-4" && result[:temperature] == 0.7 && result[:max_tokens] == 500
  puts "✅ PASS: All metadata returned correctly"
else
  puts "❌ FAIL: Metadata not returned correctly"
end

# Test 3: Only uses active prompts
puts "\nTest 3: Only uses active prompts"
if !result[:content].include?("Old version")
  puts "✅ PASS: Archived prompt ignored"
else
  puts "❌ FAIL: Used archived prompt instead of active"
end

# Test 4: Handles missing variables
puts "\nTest 4: Handles missing variables"
result2 = ActivePrompt.render(:welcome_email, variables: { customer_name: "Alice" })
if result2[:content].include?("{{product_name}}")
  puts "✅ PASS: Missing variable preserved as placeholder"
else
  puts "❌ FAIL: Missing variable not handled correctly"
end

# Test 5: Error handling for non-existent prompt
puts "\nTest 5: Error handling for non-existent prompt"
begin
  ActivePrompt.render(:non_existent)
  puts "❌ FAIL: Should have raised ActiveRecord::RecordNotFound"
rescue ActiveRecord::RecordNotFound
  puts "✅ PASS: Correctly raises error for missing prompt"
end

# Example of usage in a Rails model
puts "\n\nExample: Using in a Rails model"
puts "="*50

class CustomerEmail
  attr_accessor :customer_name, :product_name
  
  def initialize(customer_name:, product_name:)
    @customer_name = customer_name
    @product_name = product_name
  end
  
  def generate_welcome_email
    prompt_data = ActivePrompt.render(:welcome_email, 
      variables: { 
        customer_name: customer_name, 
        product_name: product_name 
      }
    )
    
    # In real usage, you would pass prompt_data to your AI service
    # For demo, just return the rendered content
    prompt_data[:content]
  end
end

# Demo usage
customer = CustomerEmail.new(
  customer_name: "Sarah Connor",
  product_name: "Enterprise Suite"
)

welcome_content = customer.generate_welcome_email
puts "Generated content: #{welcome_content}"

puts "\n✅ All tests completed!"
puts "\nYou can now use ActivePrompt.render() in any Rails model to retrieve and render prompts."