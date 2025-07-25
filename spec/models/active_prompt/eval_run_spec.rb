require 'rails_helper'

RSpec.describe ActivePrompt::EvalRun, type: :model do
  describe 'associations' do
    it 'belongs to eval_set' do
      eval_run = build(:eval_run)
      expect(eval_run).to respond_to(:eval_set)
      expect(eval_run.class.reflect_on_association(:eval_set).macro).to eq(:belongs_to)
    end

    it 'belongs to prompt_version' do
      eval_run = build(:eval_run)
      expect(eval_run).to respond_to(:prompt_version)
      expect(eval_run.class.reflect_on_association(:prompt_version).macro).to eq(:belongs_to)
    end

    it 'has many eval_results with dependent destroy' do
      eval_run = build(:eval_run)
      expect(eval_run).to respond_to(:eval_results)
      association = eval_run.class.reflect_on_association(:eval_results)
      expect(association.macro).to eq(:has_many)
      expect(association.options[:dependent]).to eq(:destroy)
    end
  end

  describe 'enums' do
    let(:eval_run) { build(:eval_run) }

    it 'defines status enum with correct values' do
      expect(ActivePrompt::EvalRun.statuses).to eq({
        'pending' => 0,
        'running' => 1,
        'completed' => 2,
        'failed' => 3
      })
    end

    it 'provides status query methods' do
      prompt = create(:prompt)
      version = create(:prompt_version, prompt: prompt)
      eval_set = create(:eval_set, prompt: prompt)
      eval_run = create(:eval_run, eval_set: eval_set, prompt_version: version, status: :pending)
      
      expect(eval_run.pending?).to be true
      expect(eval_run.running?).to be false
      
      eval_run.running!
      expect(eval_run.running?).to be true
      expect(eval_run.pending?).to be false
    end

    it 'allows setting status by string or symbol' do
      eval_run.status = 'completed'
      expect(eval_run.completed?).to be true
      
      eval_run.status = :failed
      expect(eval_run.failed?).to be true
    end
  end

  describe 'scopes' do
    let(:prompt) { create(:prompt) }
    let(:version) { create(:prompt_version, prompt: prompt) }
    let(:eval_set) { create(:eval_set, prompt: prompt) }
    
    let!(:old_run) { create(:eval_run, eval_set: eval_set, prompt_version: version, created_at: 3.days.ago) }
    let!(:recent_run) { create(:eval_run, eval_set: eval_set, prompt_version: version, created_at: 1.hour.ago) }
    let!(:middle_run) { create(:eval_run, eval_set: eval_set, prompt_version: version, created_at: 1.day.ago) }

    describe '.recent' do
      it 'orders runs by created_at descending' do
        expect(ActivePrompt::EvalRun.recent).to eq([recent_run, middle_run, old_run])
      end
    end

    describe '.by_status' do
      let!(:completed_run) { create(:eval_run, eval_set: eval_set, prompt_version: version, status: :completed) }
      let!(:failed_run) { create(:eval_run, eval_set: eval_set, prompt_version: version, status: :failed) }
      
      it 'filters runs by status' do
        expect(ActivePrompt::EvalRun.by_status(:completed)).to include(completed_run)
        expect(ActivePrompt::EvalRun.by_status(:completed)).not_to include(failed_run)
      end
    end

    describe '.successful' do
      let!(:successful_run) { create(:eval_run, eval_set: eval_set, prompt_version: version, 
                                     status: :completed, total_count: 10, passed_count: 8) }
      let!(:failed_all_run) { create(:eval_run, eval_set: eval_set, prompt_version: version,
                                     status: :completed, total_count: 10, passed_count: 0) }
      let!(:pending_run) { create(:eval_run, eval_set: eval_set, prompt_version: version,
                                  status: :pending) }
      
      it 'returns completed runs with at least one passed test' do
        results = ActivePrompt::EvalRun.successful
        expect(results).to include(successful_run)
        expect(results).not_to include(failed_all_run)
        expect(results).not_to include(pending_run)
      end
    end
  end

  describe 'instance methods' do
    let(:prompt) { create(:prompt) }
    let(:version) { create(:prompt_version, prompt: prompt) }
    let(:eval_set) { create(:eval_set, prompt: prompt) }
    let(:eval_run) { create(:eval_run, eval_set: eval_set, prompt_version: version) }

    describe '#success_rate' do
      it 'calculates percentage of passed tests' do
        eval_run.total_count = 20
        eval_run.passed_count = 15
        expect(eval_run.success_rate).to eq(75.0)
      end

      it 'returns 0 when total_count is zero' do
        eval_run.total_count = 0
        eval_run.passed_count = 0
        expect(eval_run.success_rate).to eq(0)
      end

      it 'handles all tests passing' do
        eval_run.total_count = 10
        eval_run.passed_count = 10
        expect(eval_run.success_rate).to eq(100.0)
      end

      it 'rounds to one decimal place' do
        eval_run.total_count = 3
        eval_run.passed_count = 2
        expect(eval_run.success_rate).to eq(66.7)
      end
    end

    describe '#duration' do
      it 'calculates duration between started_at and completed_at' do
        eval_run.started_at = Time.current
        eval_run.completed_at = eval_run.started_at + 2.hours + 30.minutes
        
        expect(eval_run.duration).to eq(9000) # 2.5 hours in seconds
      end

      it 'returns nil when started_at is nil' do
        eval_run.started_at = nil
        eval_run.completed_at = Time.current
        expect(eval_run.duration).to be_nil
      end

      it 'returns nil when completed_at is nil' do
        eval_run.started_at = Time.current
        eval_run.completed_at = nil
        expect(eval_run.duration).to be_nil
      end
    end

    describe '#duration_in_words' do
      context 'when not started' do
        it 'returns "Not started"' do
          eval_run.started_at = nil
          expect(eval_run.duration_in_words).to eq("Not started")
        end
      end

      context 'when running' do
        it 'returns "Running"' do
          eval_run.status = :running
          eval_run.started_at = Time.current
          expect(eval_run.duration_in_words).to eq("Running")
        end
      end

      context 'when failed without completion' do
        it 'returns "Failed"' do
          eval_run.status = :failed
          eval_run.started_at = Time.current
          eval_run.completed_at = nil
          expect(eval_run.duration_in_words).to eq("Failed")
        end
      end

      context 'when completed' do
        before { eval_run.status = :completed }

        it 'returns seconds for short durations' do
          eval_run.started_at = Time.current
          eval_run.completed_at = eval_run.started_at + 45.seconds
          expect(eval_run.duration_in_words).to eq("45 seconds")
        end

        it 'returns minutes for medium durations' do
          eval_run.started_at = Time.current
          eval_run.completed_at = eval_run.started_at + 15.minutes
          expect(eval_run.duration_in_words).to eq("15 minutes")
        end

        it 'returns hours for long durations' do
          eval_run.started_at = Time.current
          eval_run.completed_at = eval_run.started_at + 2.5.hours
          expect(eval_run.duration_in_words).to eq("2.5 hours")
        end
      end
    end
  end

  describe 'OpenAI integration fields' do
    let(:prompt) { create(:prompt) }
    let(:version) { create(:prompt_version, prompt: prompt) }
    let(:eval_set) { create(:eval_set, prompt: prompt) }
    let(:eval_run) { create(:eval_run, eval_set: eval_set, prompt_version: version) }

    it 'can store OpenAI run ID' do
      eval_run.openai_run_id = 'run_abc123'
      eval_run.save!
      
      reloaded = ActivePrompt::EvalRun.find(eval_run.id)
      expect(reloaded.openai_run_id).to eq('run_abc123')
    end

    it 'can store OpenAI file ID' do
      eval_run.openai_file_id = 'file_xyz789'
      eval_run.save!
      
      reloaded = ActivePrompt::EvalRun.find(eval_run.id)
      expect(reloaded.openai_file_id).to eq('file_xyz789')
    end

    it 'can store report URL' do
      eval_run.report_url = 'https://platform.openai.com/evals/run_abc123'
      eval_run.save!
      
      reloaded = ActivePrompt::EvalRun.find(eval_run.id)
      expect(reloaded.report_url).to eq('https://platform.openai.com/evals/run_abc123')
    end
  end

  describe 'counts and error handling' do
    let(:prompt) { create(:prompt) }
    let(:version) { create(:prompt_version, prompt: prompt) }
    let(:eval_set) { create(:eval_set, prompt: prompt) }
    let(:eval_run) { create(:eval_run, eval_set: eval_set, prompt_version: version) }

    it 'initializes counts to 0' do
      new_run = ActivePrompt::EvalRun.new
      expect(new_run.total_count).to eq(0)
      expect(new_run.passed_count).to eq(0)
      expect(new_run.failed_count).to eq(0)
    end

    it 'can store error messages' do
      eval_run.error_message = 'API rate limit exceeded'
      eval_run.save!
      
      reloaded = ActivePrompt::EvalRun.find(eval_run.id)
      expect(reloaded.error_message).to eq('API rate limit exceeded')
    end
  end
end