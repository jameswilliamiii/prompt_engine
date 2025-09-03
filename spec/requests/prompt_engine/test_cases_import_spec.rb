require "rails_helper"

RSpec.describe "PromptEngine::TestCases Import", type: :request do
  include PromptEngine::Engine.routes.url_helpers

  let(:prompt) { create(:prompt, content: "Hello {{name}}, your age is {{age}}") }
  let(:eval_set) { create(:eval_set, prompt: prompt) }

  before do
    # The prompt should auto-detect and create parameters based on content
    # Ensure parameters exist
    prompt.sync_parameters!

    # Verify parameters were created correctly
    expect(prompt.parameters.count).to eq(2)
    expect(prompt.parameters.pluck(:name)).to match_array(["name", "age"])
  end

  xdescribe "GET #import" do
    it "displays the import form" do
      get import_prompt_eval_set_test_cases_path(prompt, eval_set)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Import Test Cases")
      expect(response.body).to include("CSV Format")
      expect(response.body).to include("JSON Format")
    end

    it "shows required parameters" do
      get import_prompt_eval_set_test_cases_path(prompt, eval_set)

      expect(response.body).to include("name")
      expect(response.body).to include("age")
      expect(response.body).to include("expected_output")
    end
  end

  xdescribe "POST #import_preview" do
    context "with CSV file" do
      let(:valid_csv_content) do
        <<~CSV
          name,age,expected_output,description
          John,30,Hello John! You are 30 years old.,Test with John
          Jane,25,Hello Jane! You are 25 years old.,Test with Jane
        CSV
      end

      let(:csv_file) do
        Rack::Test::UploadedFile.new(
          StringIO.new(valid_csv_content),
          "text/csv",
          original_filename: "test_cases.csv"
        )
      end

      it "parses valid CSV and shows preview" do
        post import_preview_prompt_eval_set_test_cases_path(prompt, eval_set), params: {file: csv_file}

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Import Preview")
        expect(response.body).to include("<strong>2</strong> test cases will be imported")
        expect(response.body).to include("Test with John")
        expect(response.body).to include("Test with Jane")
      end

      context "with missing columns" do
        let(:invalid_csv_content) do
          <<~CSV
            name,expected_output
            John,Hello John!
          CSV
        end

        let(:invalid_csv_file) do
          Rack::Test::UploadedFile.new(
            StringIO.new(invalid_csv_content),
            "text/csv",
            original_filename: "invalid.csv"
          )
        end

        it "shows error for missing required columns" do
          post import_preview_prompt_eval_set_test_cases_path(prompt, eval_set), params: {file: invalid_csv_file}

          expect(response).to have_http_status(:success)
          expect(response.body).to include("Missing required column: age")
        end
      end

      context "with malformed CSV" do
        let(:malformed_csv_content) do
          'name,age,expected_output"unclosed quote'
        end

        let(:malformed_csv_file) do
          Rack::Test::UploadedFile.new(
            StringIO.new(malformed_csv_content),
            "text/csv",
            original_filename: "malformed.csv"
          )
        end

        it "shows error for malformed CSV" do
          post import_preview_prompt_eval_set_test_cases_path(prompt, eval_set), params: {file: malformed_csv_file}

          expect(response).to have_http_status(:success)
          expect(response.body).to include("Invalid CSV format")
        end
      end
    end

    context "with JSON file" do
      let(:valid_json_content) do
        [
          {
            input_variables: {name: "John", age: "30"},
            expected_output: "Hello John! You are 30 years old.",
            description: "Test with John"
          },
          {
            input_variables: {name: "Jane", age: "25"},
            expected_output: "Hello Jane! You are 25 years old."
          }
        ].to_json
      end

      let(:json_file) do
        Rack::Test::UploadedFile.new(
          StringIO.new(valid_json_content),
          "application/json",
          original_filename: "test_cases.json"
        )
      end

      it "parses valid JSON and shows preview" do
        post import_preview_prompt_eval_set_test_cases_path(prompt, eval_set), params: {file: json_file}

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Import Preview")
        expect(response.body).to include("<strong>2</strong> test cases will be imported")
        expect(response.body).to include("Test with John")
      end

      context "with invalid JSON structure" do
        let(:invalid_json_content) do
          {not_an_array: true}.to_json
        end

        let(:invalid_json_file) do
          Rack::Test::UploadedFile.new(
            StringIO.new(invalid_json_content),
            "application/json",
            original_filename: "invalid.json"
          )
        end

        it "shows error for non-array JSON" do
          post import_preview_prompt_eval_set_test_cases_path(prompt, eval_set), params: {file: invalid_json_file}

          expect(response).to have_http_status(:success)
          expect(response.body).to include("JSON must be an array of objects")
        end
      end

      context "with missing required fields" do
        let(:missing_fields_json) do
          [
            {
              input_variables: {name: "John"},
              expected_output: "Hello John!"
            }
          ].to_json
        end

        let(:missing_fields_file) do
          Rack::Test::UploadedFile.new(
            StringIO.new(missing_fields_json),
            "application/json",
            original_filename: "missing_fields.json"
          )
        end

        it "shows error for missing parameters" do
          post import_preview_prompt_eval_set_test_cases_path(prompt, eval_set), params: {file: missing_fields_file}

          expect(response).to have_http_status(:success)
          expect(response.body).to include("missing required parameters: age")
        end
      end
    end

    context "without file" do
      it "redirects back with error" do
        post import_preview_prompt_eval_set_test_cases_path(prompt, eval_set)

        expect(response).to redirect_to(import_prompt_eval_set_test_cases_path(prompt, eval_set))
        expect(flash[:alert]).to eq("Please select a file to import.")
      end
    end

    context "with unsupported file type" do
      let(:txt_file) do
        Rack::Test::UploadedFile.new(
          StringIO.new("some text"),
          "text/plain",
          original_filename: "test.txt"
        )
      end

      it "shows error for unsupported format" do
        post import_preview_prompt_eval_set_test_cases_path(prompt, eval_set), params: {file: txt_file}

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Unsupported file format")
      end
    end
  end

  xdescribe "POST #import_create" do
    let(:import_data) do
      [
        {
          input_variables: {"name" => "John", "age" => "30"},
          expected_output: "Hello John! You are 30 years old.",
          description: "Test with John"
        },
        {
          input_variables: {"name" => "Jane", "age" => "25"},
          expected_output: "Hello Jane! You are 25 years old.",
          description: nil
        }
      ]
    end

    context "with valid session data" do
      xit "creates test cases successfully (session handling in request specs)" do
        # This simulates the complete flow including preview
        # First, upload and preview the file
        csv_file = Rack::Test::UploadedFile.new(
          Rails.root.join("spec/fixtures/test_cases.csv"),
          "text/csv"
        )

        post import_preview_prompt_eval_set_test_cases_path(prompt, eval_set), params: {
          file: csv_file
        }

        # Verify the preview was successful
        expect(response).to have_http_status(:success)

        # Check if there are any errors shown in the preview
        if response.body.include?("alert") || response.body.include?("error")
          puts "Preview response body:"
          puts response.body
        end

        # Debug: Check if session was set
        # In Rails 5+, we can't directly access session in request specs
        # but we should be able to see the result in the response

        # Now the session should have the imported data
        # Create the test cases
        expect {
          post import_create_prompt_eval_set_test_cases_path(prompt, eval_set)
        }.to change { eval_set.test_cases.count }.by(2)

        # Should redirect to eval_set path
        expect(response).to redirect_to(prompt_eval_set_path(prompt, eval_set))

        # Check flash message
        if flash[:alert].present?
          puts "Flash alert: #{flash[:alert]}"
        end
        expect(flash[:notice]).to eq("Successfully imported 2 test cases.")

        # Verify created test cases
        test_cases = eval_set.test_cases.order(:id)

        expect(test_cases.first.input_variables).to eq({"name" => "John", "age" => "30"})
        expect(test_cases.first.expected_output).to eq("Hello John, your age is 30")
        expect(test_cases.first.description).to eq("Test with John")

        expect(test_cases.second.input_variables).to eq({"name" => "Jane", "age" => "25"})
        expect(test_cases.second.expected_output).to eq("Hello Jane, your age is 25")
        expect(test_cases.second.description).to be_blank
      end
    end

    context "without session data" do
      it "redirects back with error" do
        post import_create_prompt_eval_set_test_cases_path(prompt, eval_set)

        expect(response).to redirect_to(import_prompt_eval_set_test_cases_path(prompt, eval_set))
        expect(flash[:alert]).to eq("No import data found. Please upload a file again.")
      end
    end

    context "with validation errors" do
      let(:invalid_import_data) do
        [
          {
            input_variables: {"name" => "John", "age" => "30"},
            expected_output: "",  # Invalid: empty expected_output
            description: "Invalid test"
          }
        ]
      end

      it "reports validation errors" do
        post import_preview_prompt_eval_set_test_cases_path(prompt, eval_set), params: {
          file: Rack::Test::UploadedFile.new(
            Rails.root.join("spec/fixtures/invalid_test_cases.csv"),
            "text/csv"
          )
        }

        post import_create_prompt_eval_set_test_cases_path(prompt, eval_set)

        expect(response).to redirect_to(prompt_eval_set_path(prompt, eval_set))
        expect(flash[:alert]).to include("Import completed with errors")
        expect(flash[:alert]).to include("Row 1")
      end
    end
  end
end
