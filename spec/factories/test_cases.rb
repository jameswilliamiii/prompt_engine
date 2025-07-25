FactoryBot.define do
  factory :test_case, class: 'ActivePrompt::TestCase' do
    association :eval_set, factory: :eval_set
    input_variables { { "topic" => "artificial intelligence", "tone" => "professional" } }
    expected_output { "Artificial intelligence is a transformative technology..." }
    description { "Test case for AI topic" }
  end
end