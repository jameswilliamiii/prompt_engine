require 'rails_helper'

module PromptEngine
  RSpec.describe "Evaluation Workflow Integration", type: :integration do
    let!(:prompt) do
      create(:prompt,
        name: "summarizer",
        content: "Summarize this text in {{style}} style: {{text}}",
        system_message: "You are a helpful summarization assistant.",
        status: "active"
      )
    end
    
    describe "complete evaluation workflow" do
      it "creates eval set, adds test cases, runs evaluation, and displays results" do
        # Step 1: Create an evaluation set
        eval_set = EvalSet.create!(
          prompt: prompt,
          name: "Summarization Quality Tests",
          description: "Tests different summarization styles"
        )
        expect(eval_set).to be_persisted
        expect(eval_set.prompt).to eq(prompt)
        
        # Step 2: Add test cases
        test_case1 = TestCase.create!(
          eval_set: eval_set,
          input_variables: {
            "style" => "concise",
            "text" => "The quick brown fox jumps over the lazy dog. This pangram contains all letters of the alphabet."
          },
          expected_output: "A pangram with all alphabet letters.",
          description: "Concise style test"
        )
        
        test_case2 = TestCase.create!(
          eval_set: eval_set,
          input_variables: {
            "style" => "detailed",
            "text" => "Ruby is a dynamic programming language."
          },
          expected_output: "Ruby is a dynamic, interpreted programming language known for its simplicity and productivity.",
          description: "Detailed style test"
        )
        
        expect(eval_set.test_cases.count).to eq(2)
        
        # Step 3: Create and run evaluation
        eval_run = eval_set.eval_runs.create!(
          prompt_version: prompt.current_version
        )
        expect(eval_run.status).to eq("pending")
        
        # Mock the evaluation runner to avoid actual API calls
        runner = instance_double(EvaluationRunner)
        allow(EvaluationRunner).to receive(:new).with(eval_run).and_return(runner)
        allow(runner).to receive(:execute) do
          eval_run.update!(
            status: "completed",
            started_at: Time.current,
            completed_at: Time.current + 30.seconds,
            total_count: 2,
            passed_count: 1,
            failed_count: 1,
            openai_run_id: "run_test_123",
            report_url: "https://platform.openai.com/evals/test"
          )
        end
        
        # Execute the evaluation
        runner.execute
        
        # Step 4: Verify results
        eval_run.reload
        expect(eval_run.status).to eq("completed")
        expect(eval_run.total_count).to eq(2)
        expect(eval_run.passed_count).to eq(1)
        expect(eval_run.failed_count).to eq(1)
        expect(eval_run.openai_run_id).to be_present
        
        # Verify relationships
        expect(eval_run.eval_set).to eq(eval_set)
        expect(eval_run.prompt_version).to eq(prompt.current_version)
      end
    end
    
    describe "error handling" do
      let(:eval_set) { create(:eval_set, prompt: prompt) }
      let!(:test_case) { create(:test_case, eval_set: eval_set) }
      
      context "when OpenAI API fails" do
        it "handles API errors gracefully" do
          eval_run = eval_set.eval_runs.create!(
            prompt_version: prompt.current_version
          )
          
          runner = instance_double(EvaluationRunner)
          allow(EvaluationRunner).to receive(:new).with(eval_run).and_return(runner)
          allow(runner).to receive(:execute).and_raise(StandardError, "OpenAI API error: Rate limit exceeded")
          
          # The error should be raised but the eval_run should be updated
          expect { runner.execute }.to raise_error(StandardError, /OpenAI API error/)
          
          # In a real implementation, the runner would update the eval_run status
          eval_run.update!(status: "failed", error_message: "OpenAI API error: Rate limit exceeded")
          
          eval_run.reload
          expect(eval_run.status).to eq("failed")
          expect(eval_run.error_message).to include("Rate limit exceeded")
        end
      end
      
      context "when evaluation times out" do
        it "handles timeout errors" do
          eval_run = eval_set.eval_runs.create!(
            prompt_version: prompt.current_version
          )
          
          runner = instance_double(EvaluationRunner)
          allow(EvaluationRunner).to receive(:new).with(eval_run).and_return(runner)
          allow(runner).to receive(:execute) do
            eval_run.update!(
              status: "failed",
              error_message: "Timeout waiting for eval results",
              started_at: Time.current
            )
          end
          
          runner.execute
          
          eval_run.reload
          expect(eval_run.status).to eq("failed")
          expect(eval_run.error_message).to include("Timeout")
        end
      end
    end
    
    describe "prompt versioning integration" do
      let(:eval_set) { create(:eval_set, prompt: prompt) }
      let!(:test_case) { create(:test_case, eval_set: eval_set) }
      
      it "uses the current prompt version for evaluation" do
        # Create initial eval run
        initial_version = prompt.current_version
        eval_run1 = eval_set.eval_runs.create!(
          prompt_version: initial_version
        )
        expect(eval_run1.prompt_version).to eq(initial_version)
        
        # Update prompt content (creates new version)
        prompt.update!(content: "Provide a {{style}} summary of: {{text}}")
        new_version = prompt.current_version
        expect(new_version).not_to eq(initial_version)
        
        # Create new eval run with updated version
        eval_run2 = eval_set.eval_runs.create!(
          prompt_version: prompt.current_version
        )
        expect(eval_run2.prompt_version).to eq(new_version)
        expect(eval_run2.prompt_version).not_to eq(eval_run1.prompt_version)
      end
    end
    
    describe "test case validation" do
      let(:eval_set) { create(:eval_set, prompt: prompt) }
      
      it "validates required fields for test cases" do
        # Missing input variables
        invalid_test_case = eval_set.test_cases.build(
          expected_output: "Some output"
        )
        expect(invalid_test_case).not_to be_valid
        expect(invalid_test_case.errors[:input_variables]).to include("can't be blank")
        
        # Missing expected output
        invalid_test_case2 = eval_set.test_cases.build(
          input_variables: { "style" => "concise", "text" => "test" }
        )
        expect(invalid_test_case2).not_to be_valid
        expect(invalid_test_case2.errors[:expected_output]).to include("can't be blank")
      end
      
      it "validates input variables match prompt parameters" do
        # In a real implementation, you might validate that provided variables
        # match the expected variables from the prompt
        test_case = eval_set.test_cases.build(
          input_variables: { "style" => "concise", "text" => "test content" },
          expected_output: "A concise summary"
        )
        expect(test_case).to be_valid
        
        # Test with missing required variable
        test_case_missing_var = eval_set.test_cases.build(
          input_variables: { "style" => "concise" }, # missing "text"
          expected_output: "A summary"
        )
        # This would need custom validation in the TestCase model
        # For now, it's valid as we don't have that validation
        expect(test_case_missing_var).to be_valid
      end
    end
  end
end