Phase 1: Core Data Models and Infrastructure

1. Data Model Architecture

# Core evaluation models

ActivePrompt::EvalSet - Groups of test cases for specific evaluation purposes - name, description,
prompt_id, eval_type (model_graded, programmatic, human) - has_many :test_cases - has_many
:eval_runs - belongs_to :prompt

ActivePrompt::TestCase - Individual test scenarios - eval_set_id, input (JSON), expected_output,
metadata (JSON) - evaluation_criteria (for LLM judge) - weight (for weighted scoring) - tags (for
categorization)

ActivePrompt::EvalRun - Execution of an evaluation set - eval_set_id, prompt_version_id, status,
started_at, completed_at - configuration (model, temperature, etc.) - aggregate_metrics (JSON) -
has_many :eval_results

ActivePrompt::EvalResult - Individual test case results - eval_run_id, test_case_id, actual_output,
score - evaluation_details (JSON for judge reasoning) - execution_time, token_count - pass/fail
status

Phase 2: Evaluation Engine

2. Evaluator Services

# Base evaluator interface

ActivePrompt::Evaluators::Base - evaluate(test_case, actual_output) - supports_batch? -
batch_evaluate(test_cases, outputs)

# Specific evaluators

ActivePrompt::Evaluators::ExactMatch - Simple string comparison - what is this?
ActivePrompt::Evaluators::RegexMatch - Pattern matching ActivePrompt::Evaluators::ContainsAll -
Check for required elements ActivePrompt::Evaluators::JsonSchema - Validate JSON structure - what is
this ActivePrompt::Evaluators::LlmJudge - Model-graded evaluation
ActivePrompt::Evaluators::Similarity - Semantic similarity scoring

3. LLM-as-Judge Implementation ActivePrompt::LlmJudge

   - Configurable judge prompts for different criteria:
     - Accuracy/Correctness
     - Helpfulness
     - Relevance
     - Conciseness
     - Toxicity/Safety
     - Hallucination detection
   - Support for chain-of-thought reasoning
   - Calibration with human-labeled examples

Phase 3: Test Case Management

4. Synthetic Data Generation ActivePrompt::TestCaseGenerator

   - generate_from_prompt(prompt, count, strategy)
   - Strategies:
     - Boundary cases
     - Edge cases
     - Common variations
     - Adversarial examples
   - Uses prompt's parameters to generate diverse inputs

5. Import/Export System - not a priority

- CSV format: input, expected_output, metadata columns
- JSON format for complex nested data
- Bulk operations with validation
- Template library for common evaluation types

Phase 4: Evaluation Execution

6. Runner Architecture ActivePrompt::EvaluationRunner

   simplify this for MVP

   - Parallel execution using Sidekiq - is this not needed
   - Progress tracking with ActionCable
   - Configurable timeout and retry logic
   - Cost estimation before execution
   - Sampling strategies for large test sets

7. Metrics Calculation ActivePrompt::Metrics::Calculator

   - Binary classification: accuracy, precision, recall, F1
   - Multi-class: macro/micro averages
   - Regression: MSE, MAE, R²
   - Custom metrics via plugin system
   - Confidence intervals and statistical significance

Phase 5: User Interface

Can we replicate the OpenAI evals interface?

8. Evaluation Management UI /prompts/:id/evaluations

   - List of evaluation sets
   - Create new eval set wizard
   - Test case editor with preview
   - Bulk import interface - not needed

/eval_sets/:id - Test case management - Run evaluation button - Configuration options - History of
runs

/eval_runs/:id - Real-time progress - Results table with filtering - Metric dashboards - Export
results

9. Results Visualization

- Confusion matrices for classification
- Score distributions
- Performance over time charts
- Version comparison heatmaps
- Failure analysis views

Phase 6: Advanced Features - not needed for MVP

10. A/B Testing Framework

- Compare multiple prompt versions
- Statistical significance testing
- Winner selection criteria
- Automated rollout based on results

11. Continuous Evaluation

- Schedule periodic evaluations
- Monitor for performance degradation
- Alert on threshold violations
- Integration with deployment pipeline

12. Human-in-the-Loop

- Annotation interface for human judges
- Inter-rater reliability metrics
- Calibration of LLM judges with human feedback
- Crowdsourcing integration

Phase 7: Integration and APIs

We need to write a simple OpenAI client for these end points as RubyLLM doesnt support them

13. RESTful API POST /api/eval_sets/:id/run GET /api/eval_runs/:id GET /api/eval_runs/:id/results
    POST /api/test_cases/generate

14. Webhooks and Events We need setup instructions for this - is it possible to get this info
    without the webhook from the API?

- eval_run.started
- eval_run.completed
- eval_run.failed
- threshold.violated

Implementation Priority Order

Sprint 1 (Core Foundation)

- Basic data models
- Simple evaluators (exact match, contains)
- Manual test case creation
- Basic UI for running evaluations

Sprint 2 (LLM Judge)

- LLM-as-Judge implementation
- Metric calculations
- Results visualization
- Import/export functionality

Sprint 3 (Automation)

- Synthetic data generation
- Parallel execution
- Version comparison
- API endpoints

Sprint 4 (Production Ready)

- Continuous evaluation
- Human evaluation workflow
- Advanced visualizations
- Performance optimizations

This comprehensive evaluation system will enable ActivePrompt users to systematically test and
improve their prompts, ensuring consistent quality and performance across different versions and use
cases.
