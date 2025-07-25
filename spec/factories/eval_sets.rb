FactoryBot.define do
  factory :eval_set, class: 'ActivePrompt::EvalSet' do
    association :prompt, factory: :prompt
    sequence(:name) { |n| "Eval Set #{n}" }
    description { "Test evaluation set for RSpec" }
  end
end