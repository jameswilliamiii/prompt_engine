# Create sample prompts for testing
puts "Seeding database..."

# Clear existing data
ActivePrompt::Prompt.destroy_all

# Create sample prompts
prompt1 = ActivePrompt::Prompt.new
prompt1.name = "Customer Support Response"
prompt1.description = "Generates helpful customer support responses"
prompt1.content = "Please provide a helpful and empathetic response to the following customer inquiry: {{customer_message}}"
prompt1.system_message = "You are a helpful customer support agent. Be professional, empathetic, and solution-oriented."
prompt1.model = "gpt-4"
prompt1.temperature = 0.7
prompt1.max_tokens = 500
prompt1.status = "active"
prompt1.save!

prompt2 = ActivePrompt::Prompt.new
prompt2.name = "Product Description Writer"
prompt2.description = "Creates engaging product descriptions"
prompt2.content = "Write an engaging product description for: {{product_name}}. Key features: {{features}}"
prompt2.model = "gpt-3.5-turbo"
prompt2.temperature = 0.8
prompt2.max_tokens = 300
prompt2.status = "active"
prompt2.save!

prompt3 = ActivePrompt::Prompt.new
prompt3.name = "Email Subject Line Generator"
prompt3.description = "Generates catchy email subject lines"
prompt3.content = "Generate 5 compelling email subject lines for: {{email_topic}}"
prompt3.model = "claude-3-haiku"
prompt3.temperature = 0.9
prompt3.max_tokens = 150
prompt3.status = "draft"
prompt3.save!

puts "Created #{ActivePrompt::Prompt.count} sample prompts!"
