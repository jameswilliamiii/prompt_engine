require 'rails_helper'

RSpec.describe "Evaluation Workflow", type: :system do
  # This test uses VCR to record/replay API interactions
  # To record new cassettes, delete the existing ones and set VCR to :record => :new_episodes
  
  let!(:prompt) do
    create(:prompt,
      name: "Text Classifier",
      content: "Classify this text as positive, negative, or neutral: {{text}}",
      system_message: "You are a sentiment analysis assistant. Respond with only one word: positive, negative, or neutral.",
      model: "gpt-3.5-turbo",
      temperature: 0.0,  # Low temperature for consistent results
      status: "active"
    )
  end
  
  describe "complete workflow with UI", js: true do
    it "creates eval set, adds test cases, runs evaluation, and displays results" do
      # Step 1: Navigate to prompts
      visit active_prompt.prompts_path
      expect(page).to have_content(prompt.name)
      
      # Navigate to the prompt
      click_link prompt.name
      expect(page).to have_content("Evaluations")
      
      # Step 2: Create an evaluation set
      click_link "Evaluations"
      expect(page).to have_content("Evaluation Sets")
      
      click_link "New Evaluation Set"
      fill_in "Name", with: "Sentiment Analysis Tests"
      fill_in "Description", with: "Testing sentiment classification accuracy"
      click_button "Create Evaluation set"
      
      expect(page).to have_content("Evaluation set was successfully created")
      expect(page).to have_content("Sentiment Analysis Tests")
      
      # Step 3: Add test cases
      click_link "Add Test Case"
      
      # First test case - positive sentiment
      within "#test_case_input_variables_text" do
        fill_in with: "I love this product! It's amazing and works perfectly."
      end
      fill_in "Expected output", with: "positive"
      fill_in "Description", with: "Positive sentiment test"
      click_button "Create Test case"
      
      expect(page).to have_content("Positive sentiment test")
      
      # Add another test case - negative sentiment
      click_link "Add Test Case"
      within "#test_case_input_variables_text" do
        fill_in with: "This is terrible. I hate it and want my money back."
      end
      fill_in "Expected output", with: "negative"
      fill_in "Description", with: "Negative sentiment test"
      click_button "Create Test case"
      
      # Add neutral test case
      click_link "Add Test Case"
      within "#test_case_input_variables_text" do
        fill_in with: "The product arrived on Tuesday."
      end
      fill_in "Expected output", with: "neutral"
      fill_in "Description", with: "Neutral sentiment test"
      click_button "Create Test case"
      
      expect(page).to have_content("Positive sentiment test")
      expect(page).to have_content("Negative sentiment test")
      expect(page).to have_content("Neutral sentiment test")
      
      # Step 4: Run evaluation (mocked for system test)
      # In a real test with API credentials, remove this mocking
      allow_any_instance_of(ActivePrompt::EvaluationRunner).to receive(:execute) do |runner|
        eval_run = runner.instance_variable_get(:@eval_run)
        eval_run.update!(
          status: "completed",
          started_at: Time.current,
          completed_at: Time.current + 10.seconds,
          total_count: 3,
          passed_count: 2,
          failed_count: 1,
          openai_run_id: "run_test_#{SecureRandom.hex(8)}",
          report_url: "https://platform.openai.com/evals/test"
        )
      end
      
      click_button "Run Evaluation"
      
      expect(page).to have_content("Evaluation started successfully")
      
      # Step 5: View results
      expect(page).to have_content("Evaluation Run Results")
      expect(page).to have_content("Completed")
      expect(page).to have_content("2 / 3 passed")
      expect(page).to have_content("66.7%")  # Success rate
      
      # Check for OpenAI report link
      expect(page).to have_link("View OpenAI Report")
    end
  end
  
  describe "error handling in UI", js: true do
    let!(:eval_set) do
      create(:eval_set, prompt: prompt, name: "Error Test Set")
    end
    
    let!(:test_case) do
      create(:test_case, 
        eval_set: eval_set,
        input_variables: { "text" => "Test text" },
        expected_output: "positive"
      )
    end
    
    it "displays authentication error gracefully" do
      allow_any_instance_of(ActivePrompt::EvaluationRunner).to receive(:execute)
        .and_raise(ActivePrompt::OpenAiEvalsClient::AuthenticationError, "Invalid API key")
      
      visit active_prompt.prompt_eval_set_path(prompt, eval_set)
      click_button "Run Evaluation"
      
      expect(page).to have_content("Authentication failed: Please check your OpenAI API key configuration")
      expect(page).to have_current_path(active_prompt.prompt_eval_set_path(prompt, eval_set))
    end
    
    it "displays rate limit error gracefully" do
      allow_any_instance_of(ActivePrompt::EvaluationRunner).to receive(:execute)
        .and_raise(ActivePrompt::OpenAiEvalsClient::RateLimitError, "Rate limit exceeded")
      
      visit active_prompt.prompt_eval_set_path(prompt, eval_set)
      click_button "Run Evaluation"
      
      expect(page).to have_content("Rate limit exceeded: Please try again later")
    end
    
    it "displays general API errors" do
      allow_any_instance_of(ActivePrompt::EvaluationRunner).to receive(:execute)
        .and_raise(ActivePrompt::OpenAiEvalsClient::APIError, "Service unavailable")
      
      visit active_prompt.prompt_eval_set_path(prompt, eval_set)
      click_button "Run Evaluation"
      
      expect(page).to have_content("API error: Service unavailable")
    end
  end
end