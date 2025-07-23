FactoryBot.define do
  factory :prompt do
    name { "MyString" }
    description { "MyText" }
    content { "MyText" }
    system_message { "MyText" }
    model { "MyString" }
    temperature { 1.5 }
    max_tokens { 1 }
    status { "MyString" }
    metadata { "" }
  end
end
