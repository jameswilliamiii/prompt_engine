FactoryBot.define do
  factory :eval_set, class: 'PromptEngine::EvalSet' do
    association :prompt, factory: :prompt
    sequence(:name) { |n| "Eval Set #{n}" }
    description { "Test evaluation set for RSpec" }
    grader_type { "exact_match" }
    grader_config { {} }
  end
end