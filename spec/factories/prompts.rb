FactoryBot.define do
  factory :prompt, class: 'ActivePrompt::Prompt' do
    sequence(:name) { |n| "Test Prompt #{n}" }
    description { "A test prompt for RSpec" }
    content { "Tell me about {{topic}}" }
    system_message { "You are a helpful assistant." }
    model { "gpt-4" }
    temperature { 0.7 }
    max_tokens { 1000 }
    status { "draft" }
    metadata { {} }
  end
end
