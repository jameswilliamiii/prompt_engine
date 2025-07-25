# PromptEngine: Product Specification

## AI Prompt Management Engine for Rails Applications

### Executive Summary

PromptEngine is a mountable Rails engine that transforms how development teams manage AI prompts in
their applications. Instead of hardcoding prompts throughout your codebase, PromptEngine provides a
centralized admin interface where teams can create, version, test, and optimize their AI prompts
without deploying code changes.

### The Problem We're Solving

Modern Rails applications increasingly rely on AI services like OpenAI and Anthropic. However,
prompt management remains primitive:

- **Scattered Prompts**: Prompts live in constants, environment variables, or hardcoded strings
  across multiple files
- **No Version Control**: When prompts need updates, there's no history or rollback capability
- **Blind Changes**: Teams modify prompts without testing, hoping they'll work in production
- **Zero Visibility**: No analytics on which prompts are used, their performance, or costs
- **Deployment Bottleneck**: Every prompt tweak requires a code deployment

### Target Users

**Primary Users**

- **Product Engineers**: Need to iterate on prompts quickly without deployment cycles
- **Product Managers**: Want visibility into AI feature performance and costs
- **QA Engineers**: Need to test prompt behavior systematically

**Secondary Users**

- **Customer Success**: May need to understand why certain AI responses occurred
- **Finance Teams**: Need cost tracking for AI usage

### Core User Experience

#### 1. Getting Started

**First Run Experience**

- Mount the engine with one line in routes.rb
- Run migrations to set up the database
- Access the admin at `/prompt_engines`
- Create your first prompt in under 60 seconds

**Zero Configuration**

- No authentication required (assumes internal admin access)
- Works with your existing Rails setup
- Auto-detects AI service credentials from Rails credentials

#### 2. Dashboard Experience

**At-a-Glance Insights** The landing page provides immediate value with:

- Total prompts managed
- Recent prompt usage (last 24 hours)
- Error rate trends
- Token usage and estimated costs
- Quick access to recently edited prompts

**Visual Design**

- Clean, modern interface using CSS3 and BEM with styles that match the simplicity of shadcn/ui
  components without using React
- Consistent with Rails admin conventions

#### 3. Prompt Management

**Creating a Prompt**

Users click "New Prompt" and see a thoughtfully designed form:

1. **Basic Information**

   - Name: Human-readable identifier (e.g., "Customer Support Response")
   - Slug: Auto-generated URL-safe identifier (e.g., "customer_support_response")
   - Description: Optional context for team members

2. **Prompt Configuration**

   - System Message: Separate textarea for AI system instructions
   - User Prompt: Main prompt with variable placeholder support
   - Visual indicator for variables (highlighted as `{{variable_name}}`)

3. **Parameter Definition**

   - Auto-detected from prompt template
   - For each parameter, specify:
     - Type (string, number, boolean)
     - Required/optional
     - Default value
     - Description for documentation

4. **Model Settings**
   - Model selection (GPT-4, Claude, etc.)
   - Temperature, max tokens, and other model-specific settings
   - Cost estimate based on average usage

**Smart Features**

- **Live Preview**: See how prompts render with sample data
- **Variable Validation**: Warns about undefined or unused variables
- **Cost Calculator**: Estimates cost per prompt execution
- **Syntax Highlighting**: Makes complex prompts readable

#### 4. Version Control

**Version History View** Each prompt shows its complete history:

- Version number and timestamp
- Who made the change
- Diff view showing exactly what changed
- Deployment status (draft/staging/production)
- Performance metrics for each version

**Version Actions**

- **Compare**: Side-by-side diff of any two versions
- **Restore**: One-click rollback to previous versions
- **Clone**: Create new version based on existing one
- **Tag**: Mark versions for different environments

#### 5. Testing Playground

**Interactive Testing** The playground provides a safe space to experiment:

1. **Parameter Input Form**

   - Dynamic form based on defined parameters
   - Sample data suggestions
   - Recent test history for quick re-runs

2. **Test Execution**

   - Real-time API calls to chosen AI service
   - Response streaming for long outputs
   - Token count and cost display
   - Response time tracking

3. **Result Analysis**
   - Formatted response display
   - JSON/Markdown rendering support
   - Copy button for outputs
   - Save notable tests for future reference

#### 6. Evaluation Suite

**Creating Eval Tests** Simple interface for building test suites:

1. **Test Case Builder**

   - Name each test scenario
   - Define input parameters
   - Specify expected outcomes
   - Choose evaluation type:
     - Exact match
     - Contains keywords
     - JSON structure validation
     - Semantic similarity
     - Custom LLM judge

2. **Bulk Import**
   - CSV upload for multiple test cases
   - Template download for correct format
   - Validation before import

**Running Evaluations** Clean evaluation runner interface:

1. **Version Selection**

   - Compare up to 3 versions simultaneously
   - Visual indicators for current production version
   - Include/exclude draft versions

2. **Results Dashboard**
   - Pass/fail summary for each version
   - Detailed comparison table
   - Failed test investigation tools
   - Cost per version comparison
   - Export results as CSV

#### 7. Analytics & Monitoring

**Usage Analytics** Comprehensive insights into prompt performance:

- **Usage Frequency**: Which prompts are called most
- **Performance Metrics**: Average response time by prompt
- **Error Tracking**: Failed executions with error messages
- **Cost Analysis**: Token usage and spend by prompt/version
- **Trend Visualization**: Charts showing changes over time

**Filtering & Segmentation**

- By date range
- By environment (development/staging/production)
- By prompt or version
- By success/failure status

#### 8. Developer Integration

**Simple API**

```ruby
# In your application code
response = PromptEngine.render(:customer_support,
  customer_name: @customer.name,
  issue: @ticket.description
)
```

**Smart Features**

- **Caching**: Automatic caching of rendered prompts
- **Fallbacks**: Define backup prompts for resilience
- **Async Support**: Background job integration
- **Callbacks**: Hooks for custom logging/monitoring

### Key User Flows

#### Flow 1: Improving an Underperforming Prompt

1. **Identify Issue**: Dashboard shows high error rate for "email_classifier" prompt
2. **Investigate**: Click through to see common failure patterns
3. **Create Test Suite**: Build eval tests covering failure cases
4. **Iterate**: Create new version with improvements
5. **Validate**: Run eval suite comparing versions
6. **Deploy**: Promote better performing version to production
7. **Monitor**: Watch metrics improve in real-time

#### Flow 2: Cost Optimization

1. **Analyze Costs**: Analytics show "summary_generator" using excessive tokens
2. **Experiment**: Test different prompt phrasings in playground
3. **Measure**: Use eval suite to ensure quality maintained
4. **Optimize**: Find version using 40% fewer tokens with same quality
5. **Save**: Deploy optimized version, see immediate cost reduction

#### Flow 3: New Feature Development

1. **Prototype**: Create new prompt in development environment
2. **Test**: Use playground to refine with real data
3. **Evaluate**: Build test suite for edge cases
4. **Collaborate**: Share prompt link with team for feedback
5. **Deploy**: Gradually roll out through staging to production

### Future Vision

PromptEngine becomes the standard for AI prompt management in Rails applications, expanding to
support:

- Multi-language prompt variants
- A/B testing framework
- Prompt marketplace for common use cases
- Advanced analytics with ML-powered optimization suggestions
- Team collaboration features

### Summary

PromptEngine transforms AI prompt management from a development bottleneck into a competitive
advantage. By providing visibility, control, and optimization capabilities in a familiar Rails admin
interface, teams can iterate faster, reduce costs, and deliver better AI-powered features to their
users.

The magic is in the simplicity—mount it, use it, ship better AI features. No complex setup, no
external dependencies, just a tool that solves a real problem elegantly.
