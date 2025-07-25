module ActivePrompt
  class EvalSetsController < ApplicationController
    before_action :set_prompt
    before_action :set_eval_set, only: [:show, :edit, :update, :destroy, :run, :compare, :metrics]
    
    def index
      @eval_sets = @prompt.eval_sets
    end
    
    def show
      @test_cases = @eval_set.test_cases
      @recent_runs = @eval_set.eval_runs.order(created_at: :desc).limit(5)
    end
    
    def new
      @eval_set = @prompt.eval_sets.build
    end
    
    def create
      @eval_set = @prompt.eval_sets.build(eval_set_params)
      
      if @eval_set.save
        redirect_to prompt_eval_set_path(@prompt, @eval_set), notice: "Evaluation set was successfully created."
      else
        flash.now[:alert] = "Please fix the errors below."
        render :new
      end
    end
    
    def edit
    end
    
    def update
      if @eval_set.update(eval_set_params)
        redirect_to prompt_eval_set_path(@prompt, @eval_set), notice: "Evaluation set was successfully updated."
      else
        flash.now[:alert] = "Please fix the errors below."
        render :edit
      end
    end
    
    def destroy
      @eval_set.destroy
      redirect_to prompt_eval_sets_path(@prompt), notice: "Evaluation set was successfully deleted."
    end
    
    def run
      # Check if API key is available
      unless api_key_configured?
        redirect_to prompt_eval_set_path(@prompt, @eval_set), 
          alert: "OpenAI API key not configured. Please configure it in Settings or contact your administrator."
        return
      end
      
      # Create new eval run with current prompt version
      @eval_run = @eval_set.eval_runs.create!(
        prompt_version: @prompt.current_version
      )
      
      begin
        # Run evaluation synchronously for MVP
        ActivePrompt::EvaluationRunner.new(@eval_run).execute
        redirect_to prompt_eval_run_path(@prompt, @eval_run), notice: "Evaluation started successfully"
      rescue ActivePrompt::OpenAiEvalsClient::AuthenticationError => e
        @eval_run.update!(status: :failed, error_message: e.message)
        redirect_to prompt_eval_set_path(@prompt, @eval_set), 
          alert: "Authentication failed: Please check your OpenAI API key in Settings"
      rescue ActivePrompt::OpenAiEvalsClient::RateLimitError => e
        @eval_run.update!(status: :failed, error_message: e.message)
        redirect_to prompt_eval_set_path(@prompt, @eval_set), alert: "Rate limit exceeded: Please try again later"
      rescue ActivePrompt::OpenAiEvalsClient::APIError => e
        @eval_run.update!(status: :failed, error_message: e.message)
        redirect_to prompt_eval_set_path(@prompt, @eval_set), alert: "API error: #{e.message}"
      rescue StandardError => e
        @eval_run.update!(status: :failed, error_message: e.message)
        Rails.logger.error "Evaluation error: #{e.class} - #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        redirect_to prompt_eval_set_path(@prompt, @eval_set), alert: "Evaluation failed: #{e.message}"
      end
    end
    
    def compare
      unless params[:run_ids].present? && params[:run_ids].is_a?(Array) && params[:run_ids].length == 2
        redirect_to prompt_eval_set_path(@prompt, @eval_set), 
          alert: "Please select exactly two evaluation runs to compare."
        return
      end
      
      @run1 = @eval_set.eval_runs.find(params[:run_ids][0])
      @run2 = @eval_set.eval_runs.find(params[:run_ids][1])
      
      # Ensure both runs are completed
      unless @run1.status == 'completed' && @run2.status == 'completed'
        redirect_to prompt_eval_set_path(@prompt, @eval_set), 
          alert: "Both evaluation runs must be completed to compare them."
        return
      end
      
      # Calculate comparison metrics
      @run1_success_rate = @run1.total_count > 0 ? (@run1.passed_count.to_f / @run1.total_count * 100) : 0
      @run2_success_rate = @run2.total_count > 0 ? (@run2.passed_count.to_f / @run2.total_count * 100) : 0
      @success_rate_diff = @run2_success_rate - @run1_success_rate
    rescue ActiveRecord::RecordNotFound
      redirect_to prompt_eval_set_path(@prompt, @eval_set), 
        alert: "One or both evaluation runs could not be found."
    end
    
    def metrics
      # Get all completed runs for this eval set
      @eval_runs = @eval_set.eval_runs.where(status: 'completed').order(created_at: :asc)
      
      # Calculate metrics data for charts
      if @eval_runs.any?
        # Success rate trend data (for line chart)
        @success_rate_trend = @eval_runs.map do |run|
          {
            date: run.created_at.strftime("%b %d, %Y %I:%M %p"),
            rate: run.total_count > 0 ? (run.passed_count.to_f / run.total_count * 100).round(2) : 0,
            version: "v#{run.prompt_version.version_number}"
          }
        end
        
        # Success rate by version (for bar chart)
        version_stats = @eval_runs.group_by { |r| r.prompt_version.version_number }
        @success_rate_by_version = version_stats.map do |version, runs|
          total_passed = runs.sum(&:passed_count)
          total_count = runs.sum(&:total_count)
          {
            version: "v#{version}",
            rate: total_count > 0 ? (total_passed.to_f / total_count * 100).round(2) : 0,
            runs: runs.count
          }
        end.sort_by { |v| v[:version] }
        
        # Test case statistics
        @total_test_cases = @eval_set.test_cases.count
        @total_runs = @eval_runs.count
        @overall_pass_rate = begin
          total_passed = @eval_runs.sum(&:passed_count)
          total_tests = @eval_runs.sum(&:total_count)
          total_tests > 0 ? (total_passed.to_f / total_tests * 100).round(2) : 0
        end
        
        # Average duration trend
        @duration_trend = @eval_runs.map do |run|
          duration = if run.completed_at && run.started_at
            (run.completed_at - run.started_at).to_i
          else
            nil
          end
          {
            date: run.created_at.strftime("%b %d, %Y %I:%M %p"),
            duration: duration,
            version: "v#{run.prompt_version.version_number}"
          }
        end.compact
        
        # Recent activity (last 10 runs)
        @recent_activity = @eval_runs.last(10).reverse
      else
        @success_rate_trend = []
        @success_rate_by_version = []
        @total_test_cases = @eval_set.test_cases.count
        @total_runs = 0
        @overall_pass_rate = 0
        @duration_trend = []
        @recent_activity = []
      end
    end
    
    protected
    
    helper_method :api_key_configured?
    
    private
    
    def set_prompt
      @prompt = Prompt.find(params[:prompt_id])
    end
    
    def set_eval_set
      @eval_set = @prompt.eval_sets.find(params[:id])
    end
    
    def eval_set_params
      params.require(:eval_set).permit(:name, :description, :grader_type, grader_config: {})
    end
    
    def api_key_configured?
      # Check if OpenAI API key is available from Settings or Rails credentials
      settings = ActivePrompt::Setting.instance
      settings.openai_configured? || Rails.application.credentials.dig(:openai, :api_key).present?
    rescue ActiveRecord::RecordNotFound
      # If settings record doesn't exist, check Rails credentials
      Rails.application.credentials.dig(:openai, :api_key).present?
    end
  end
end