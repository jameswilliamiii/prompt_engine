FactoryBot.define do
  factory :prompt_version, class: 'ActivePrompt::PromptVersion' do
    association :prompt, factory: :prompt
    # version_number is automatically set by the model
    content { "Version content" }
    system_message { "You are a helpful assistant" }
    model { "gpt-4" }
    temperature { 0.7 }
    max_tokens { 1000 }
    metadata { {} }
    created_by { "test_user" }
    change_description { "Test change" }
  end
end