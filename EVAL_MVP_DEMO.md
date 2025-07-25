# PromptEngine Eval MVP Demo

The evaluation feature for PromptEngine is now fully implemented and functional! 🎉

## What's Included in the MVP

### ✅ Core Features

- **Evaluation Sets**: Create groups of test cases for specific evaluation purposes
- **Test Cases**: Define input variables and expected outputs
- **Eval Runs**: Execute evaluations against OpenAI's Evals API
- **Results Display**: View success rates and link to OpenAI reports

### ✅ Technical Implementation

- Rails 7.1+ compatible enum syntax
- OpenAI Evals API client with error handling
- EvaluationRunner service for orchestrating evaluations
- Comprehensive model validations and associations
- Full CRUD operations for eval sets and test cases

### ✅ UI/UX Features

- Clean, intuitive interface following existing design patterns
- Loading states and progress indicators
- Error handling with helpful messages
- Auto-refresh for running evaluations
- Form validation with visual feedback

## How to Use

### 1. Start the Rails Server

```bash
cd spec/dummy
bundle exec rails s
```

### 2. Navigate to a Prompt

Visit: http://localhost:3000/prompt_engine/prompts/1

### 3. Click "Evaluations"

This takes you to the evaluation sets index page.

### 4. Create an Evaluation Set

- Click "New Evaluation Set"
- Give it a name and optional description
- Save

### 5. Add Test Cases

- Click on your eval set
- Click "Add Test Case"
- Fill in the input variables (matching your prompt's {{variables}})
- Add the expected output
- Save

### 6. Run Evaluation

- Click "Run Evaluation" button
- The evaluation will be submitted to OpenAI
- View results once complete

## Configuration Requirements

### OpenAI API Key

Configure your OpenAI API key in Rails credentials:

```bash
rails credentials:edit
```

Add:

```yaml
openai:
  api_key: sk-your-openai-api-key
```

Note: The Evals API may require special access from OpenAI.

## Testing the MVP

### Quick Test (Without API)

Run the test script to verify everything works:

```bash
cd spec/dummy
bundle exec rails runner ../../test_eval_mvp.rb
```

### Full Test Suite

Run all eval-related tests:

```bash
bundle exec rspec spec/models/prompt_engine/eval*
bundle exec rspec spec/requests/prompt_engine/eval*
```

## Example Use Case

Let's say you have a customer support prompt:

**Prompt**: "Classify this support ticket as 'urgent', 'normal', or 'low': {{ticket_text}}"

**Test Cases**:

1. Input: {ticket_text: "System is down!"} → Expected: "urgent"
2. Input: {ticket_text: "How do I reset password?"} → Expected: "normal"
3. Input: {ticket_text: "Feature suggestion"} → Expected: "low"

Run the evaluation to see how well your prompt performs!

## Known Limitations (MVP)

1. **Exact Match Only**: Currently uses string_check grader (exact match)
2. **Synchronous Execution**: Evaluations run synchronously (no background jobs)
3. **Aggregate Results**: Individual test results not fetched from OpenAI
4. **No Batch Import**: Test cases must be added one at a time

## Future Enhancements

- Additional grader types (regex, contains, LLM judge)
- Background job processing with Sidekiq
- Detailed test result retrieval
- CSV import/export for test cases
- A/B testing between prompt versions
- Custom evaluation metrics

## Troubleshooting

### "OpenAI API key not configured"

- Ensure your API key is in Rails credentials
- Restart the Rails server after adding credentials

### "Rate limit exceeded"

- OpenAI Evals API has rate limits
- Wait a few minutes and try again

### Enum Error

- If you see ArgumentError about enum, restart the Rails server
- Clear Spring cache: `spring stop`

The MVP provides a solid foundation for prompt evaluation while leveraging OpenAI's robust
infrastructure!
