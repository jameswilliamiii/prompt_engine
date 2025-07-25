FactoryBot.define do
  factory :parameter, class: 'PromptEngine::Parameter' do
    sequence(:name) { |n| "param_#{n}" }
    parameter_type { 'string' }
    description { 'A test parameter' }
    required { true }
    default_value { nil }
    example_value { 'example' }
    validation_rules { {} }
    position { nil }
    association :prompt, factory: :prompt
  end
end
