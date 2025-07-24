FactoryBot.define do
  factory :playground_run_result, class: 'ActivePrompt::PlaygroundRunResult' do
    association :prompt_version, factory: :prompt_version

    provider { "anthropic" }
    model { "claude-3-5-sonnet-20241022" }
    rendered_prompt { "Tell me about {{topic}}" }
    system_message { "You are a helpful assistant." }
    parameters { { topic: "Ruby on Rails" } }
    response { "Ruby on Rails is a web application framework written in Ruby..." }
    execution_time { 1.234 }
    token_count { 150 }
    temperature { 0.7 }
    max_tokens { 1000 }

    trait :openai do
      provider { "openai" }
      model { "gpt-4o" }
    end

    trait :no_tokens do
      token_count { nil }
    end

    trait :with_long_response do
      response { "A" * 5000 }
      token_count { 2500 }
      execution_time { 5.678 }
    end
  end
end
