module ActivePrompt
  class TestCasesController < ApplicationController
    before_action :set_prompt
    before_action :set_eval_set
    before_action :set_test_case, only: [:edit, :update, :destroy]
    
    def new
      @test_case = @eval_set.test_cases.build
      # Pre-populate with prompt's parameters
      @test_case.input_variables = @prompt.parameters.each_with_object({}) do |param, hash|
        hash[param.name] = param.default_value
      end
    end
    
    def create
      @test_case = @eval_set.test_cases.build(test_case_params)
      
      if @test_case.save
        redirect_to prompt_eval_set_path(@prompt, @eval_set), notice: "Test case was successfully created."
      else
        flash.now[:alert] = "Please fix the errors below."
        render :new
      end
    end
    
    def edit
    end
    
    def update
      if @test_case.update(test_case_params)
        redirect_to prompt_eval_set_path(@prompt, @eval_set), notice: "Test case was successfully updated."
      else
        flash.now[:alert] = "Please fix the errors below."
        render :edit
      end
    end
    
    def destroy
      @test_case.destroy
      redirect_to prompt_eval_set_path(@prompt, @eval_set), notice: "Test case was successfully deleted."
    end
    
    def import
      # Display the import form
    end
    
    def import_preview
      unless params[:file].present?
        redirect_to import_prompt_eval_set_test_cases_path(@prompt, @eval_set), 
                    alert: "Please select a file to import."
        return
      end
      
      @imported_data = []
      @errors = []
      
      begin
        file_content = params[:file].read
        file_type = detect_file_type(params[:file])
        
        if file_type == :csv
          parse_csv(file_content)
        elsif file_type == :json
          parse_json(file_content)
        else
          @errors << "Unsupported file format. Please upload a CSV or JSON file."
        end
      rescue => e
        @errors << "Error reading file: #{e.message}"
      end
      
      if @errors.any?
        flash.now[:alert] = @errors.join(", ")
        render :import
      else
        # Store the imported data in session for the create action
        session[:imported_test_cases] = @imported_data
        render :import_preview
      end
    end
    
    def import_create
      imported_data = session[:imported_test_cases]
      
      unless imported_data.present?
        redirect_to import_prompt_eval_set_test_cases_path(@prompt, @eval_set), 
                    alert: "No import data found. Please upload a file again."
        return
      end
      
      success_count = 0
      errors = []
      
      imported_data.each_with_index do |data, index|
        test_case = @eval_set.test_cases.build(
          input_variables: data[:input_variables],
          expected_output: data[:expected_output],
          description: data[:description]
        )
        
        if test_case.save
          success_count += 1
        else
          errors << "Row #{index + 1}: #{test_case.errors.full_messages.join(', ')}"
        end
      end
      
      # Clear the session data
      session.delete(:imported_test_cases)
      
      if errors.any?
        flash[:alert] = "Import completed with errors: #{errors.join('; ')}"
      else
        flash[:notice] = "Successfully imported #{success_count} test cases."
      end
      
      redirect_to prompt_eval_set_path(@prompt, @eval_set)
    end
    
    private
    
    def set_prompt
      @prompt = Prompt.find(params[:prompt_id])
    end
    
    def set_eval_set
      @eval_set = @prompt.eval_sets.find(params[:eval_set_id])
    end
    
    def set_test_case
      @test_case = @eval_set.test_cases.find(params[:id])
    end
    
    def test_case_params
      params.require(:test_case).permit(:description, :expected_output, input_variables: {})
    end
    
    def detect_file_type(file)
      filename = file.original_filename.downcase
      
      if filename.ends_with?('.csv')
        :csv
      elsif filename.ends_with?('.json')
        :json
      else
        :unknown
      end
    end
    
    def parse_csv(content)
      require 'csv'
      
      # Get prompt parameters for column validation
      expected_params = @prompt.parameters.pluck(:name)
      
      CSV.parse(content, headers: true) do |row|
        # Extract input variables from prompt parameter columns
        input_variables = {}
        
        expected_params.each do |param_name|
          if row.headers.include?(param_name)
            input_variables[param_name] = row[param_name]
          else
            @errors << "Missing required column: #{param_name}"
            return
          end
        end
        
        # Check for expected_output column
        unless row.headers.include?('expected_output')
          @errors << "Missing required column: expected_output"
          return
        end
        
        # Add to imported data
        @imported_data << {
          input_variables: input_variables,
          expected_output: row['expected_output'],
          description: row['description'] # Optional column
        }
      end
    rescue CSV::MalformedCSVError => e
      @errors << "Invalid CSV format: #{e.message}"
    end
    
    def parse_json(content)
      data = JSON.parse(content)
      
      unless data.is_a?(Array)
        @errors << "JSON must be an array of objects"
        return
      end
      
      expected_params = @prompt.parameters.pluck(:name)
      
      data.each_with_index do |item, index|
        unless item.is_a?(Hash)
          @errors << "Item #{index + 1} must be an object"
          next
        end
        
        unless item['input_variables'].is_a?(Hash)
          @errors << "Item #{index + 1}: input_variables must be an object"
          next
        end
        
        unless item['expected_output'].present?
          @errors << "Item #{index + 1}: expected_output is required"
          next
        end
        
        # Validate that all required parameters are present
        missing_params = expected_params - item['input_variables'].keys
        if missing_params.any?
          @errors << "Item #{index + 1}: missing required parameters: #{missing_params.join(', ')}"
          next
        end
        
        @imported_data << {
          input_variables: item['input_variables'],
          expected_output: item['expected_output'],
          description: item['description']
        }
      end
    rescue JSON::ParserError => e
      @errors << "Invalid JSON format: #{e.message}"
    end
  end
end