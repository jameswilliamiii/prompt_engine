FactoryBot.define do
  factory :eval_result, class: 'PromptEngine::EvalResult' do
    association :eval_run, factory: :eval_run
    association :test_case, factory: :test_case
    actual_output { "Artificial intelligence is a rapidly evolving field..." }
    passed { true }
    execution_time_ms { 250 }
    error_message { nil }

    trait :failed do
      passed { false }
      error_message { "Output did not match expected result" }
    end

    trait :error do
      passed { false }
      actual_output { nil }
      error_message { "API request failed" }
    end
  end
end
