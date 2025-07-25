FactoryBot.define do
  factory :eval_run, class: 'ActivePrompt::EvalRun' do
    association :eval_set, factory: :eval_set
    association :prompt_version, factory: :prompt_version
    status { "pending" }
    started_at { nil }
    completed_at { nil }
    total_count { 0 }
    passed_count { 0 }
    failed_count { 0 }
    error_message { nil }
    openai_run_id { nil }
    openai_file_id { nil }
    report_url { nil }
    
    trait :running do
      status { "running" }
      started_at { 1.minute.ago }
    end
    
    trait :completed do
      status { "completed" }
      started_at { 5.minutes.ago }
      completed_at { 1.minute.ago }
      total_count { 10 }
      passed_count { 8 }
      failed_count { 2 }
    end
    
    trait :failed do
      status { "failed" }
      started_at { 2.minutes.ago }
      completed_at { 1.minute.ago }
      error_message { "Evaluation failed due to API error" }
    end
  end
end