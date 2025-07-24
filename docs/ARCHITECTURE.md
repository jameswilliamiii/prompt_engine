# ActivePrompt Architecture

## Overview

ActivePrompt is a Rails mountable engine that provides centralized AI prompt management for Rails applications. It enables teams to create, version, test, and optimize AI prompts through an admin interface without requiring code deployments.

## System Architecture

### Engine Structure

ActivePrompt follows Rails engine conventions with complete isolation:

- **Namespace**: All components under `ActivePrompt` module
- **Database**: Tables prefixed with `active_prompt_`
- **Assets**: Isolated under `app/assets/active_prompt/`
- **Routes**: Mounted at configurable path (e.g., `/active_prompt`)

### Technology Stack

- **Rails**: 8.0.2+ (leverages Rails 8 features)
- **Ruby**: 3.0+
- **Database**: PostgreSQL/MySQL/SQLite compatible
- **Assets**: Propshaft for asset management
- **CSS**: Custom BEM methodology (no CSS framework)
- **AI Integration**: ruby_llm gem for provider abstraction
- **Testing**: RSpec with FactoryBot

## Core Components

### Models

#### Prompt (`ActivePrompt::Prompt`)
The central model for prompt management:

**Attributes**:
- `name`: Unique identifier for prompts
- `description`: Human-readable description
- `content`: The actual prompt template with `{{variables}}`
- `system_message`: Optional system/context message
- `model_config`: JSON field for temperature, max_tokens, model selection
- `status`: Enum (draft, active, archived)
- `metadata`: JSON field for additional data
- `versions_count`: Counter cache for versions

**Key Features**:
- Automatic versioning on content/system message changes
- Variable extraction and parameter synchronization
- Render method with variable substitution
- Status-based scoping

**Associations**:
```ruby
has_many :versions, dependent: :destroy
has_many :parameters, dependent: :destroy
```

#### PromptVersion (`ActivePrompt::PromptVersion`)
Immutable snapshots of prompts:

**Attributes**:
- `prompt_id`: Reference to parent prompt
- `version_number`: Sequential version number
- `content`: Snapshot of prompt content
- `system_message`: Snapshot of system message
- `model_config`: Snapshot of model configuration
- `change_description`: Auto-generated or manual description
- `created_by`: User who created the version

**Key Features**:
- Automatic version numbering
- Restoration capability
- Change tracking
- Immutable after creation

#### Parameter (`ActivePrompt::Parameter`)
Defines expected variables in prompts:

**Attributes**:
- `prompt_id`: Reference to parent prompt
- `name`: Variable name (without braces)
- `description`: Help text for users
- `parameter_type`: Enum (string, integer, decimal, boolean, datetime, date, array, json)
- `required`: Boolean flag
- `default_value`: Default if not provided
- `validation_rules`: JSON for constraints
- `position`: Order in forms

**Key Features**:
- Type-specific form inputs
- Validation rule enforcement
- Default value handling
- Type casting

### Controllers

#### PromptsController
Main CRUD controller for prompt management:

**Actions**:
- `index`: List prompts with filtering
- `show`: Display prompt details and versions
- `new/create`: Create new prompts
- `edit/update`: Modify existing prompts
- `destroy`: Archive prompts
- `test`: Quick test interface
- `duplicate`: Clone existing prompts
- `playground`: Full testing interface
- `search`: Search prompts

**Features**:
- Strong parameters with nested attributes
- Flash notifications
- Admin layout usage
- Parameter synchronization after save

#### PlaygroundController
Interactive testing interface:

**Actions**:
- `show`: Display testing interface
- `execute`: Run prompt against AI provider

**Features**:
- Provider selection (Anthropic, OpenAI)
- Real-time execution
- Error handling
- Response formatting

#### VersionsController
Version management interface:

**Actions**:
- `index`: List all versions
- `show`: Display version details
- `restore`: Restore previous version
- `compare`: Show diff between versions

### Services

#### VariableDetector
Extracts and analyzes variables from prompt content:

**Methods**:
- `extract_variables`: Find all `{{variable}}` patterns
- `suggest_type`: Infer type from variable name
- `validate_variables`: Check for undefined variables

**Type Inference Rules**:
- Names ending in `_at`, `_on`, `date` → datetime/date
- Names ending in `_count`, `number` → integer
- Names ending in `_list`, `_array` → array
- Names ending in `?`, `is_`, `has_` → boolean

#### PlaygroundExecutor
Handles AI provider communication:

**Responsibilities**:
- Provider initialization
- API key management
- Request formatting
- Response parsing
- Error handling

**Supported Providers**:
- Anthropic Claude (claude-3-5-sonnet, etc.)
- OpenAI GPT (gpt-4o, gpt-4o-mini, etc.)

#### ParameterParser
Simple template rendering:

**Features**:
- Variable extraction
- Value substitution
- Missing variable handling

### Views & UI

#### Layout Structure

```
app/views/layouts/active_prompt/
├── application.html.erb     # Main engine layout
└── admin.html.erb           # Admin interface layout
```

**Admin Layout Features**:
- Sidebar navigation
- Flash notifications
- Responsive design
- Dark mode support

#### Component Organization

```
app/views/active_prompt/
├── prompts/
│   ├── index.html.erb       # Prompt listing
│   ├── show.html.erb        # Prompt details
│   ├── _form.html.erb       # Prompt form
│   └── _prompt.html.erb     # Prompt row partial
├── playground/
│   ├── show.html.erb        # Testing interface
│   └── _result.html.erb     # Execution results
└── versions/
    ├── index.html.erb       # Version history
    └── show.html.erb        # Version details
```

### Styling Architecture

#### CSS Structure

```
app/assets/stylesheets/active_prompt/
├── foundation.css           # Variables, reset, base styles
├── layout.css              # Page structure
├── components/
│   ├── buttons.css         # Button styles
│   ├── forms.css           # Form elements
│   ├── tables.css          # Table layouts
│   ├── cards.css           # Card components
│   └── sidebar.css         # Navigation sidebar
└── application.css         # Import manifest
```

#### Design System

**Color Variables**:
```css
--primary: #3b82f6;
--secondary: #6b7280;
--success: #10b981;
--danger: #ef4444;
--warning: #f59e0b;
```

**Spacing System**:
- Base unit: 4px
- Scale: 1, 2, 3, 4, 5, 6, 8, 10, 12, 16

**Component Naming**:
- BEM methodology: `.block__element--modifier`
- Prefix: `ap-` for all components

## Data Flow

### Prompt Creation Flow

1. User fills out prompt form
2. Controller validates input
3. Prompt model saves with transaction
4. Variable detector extracts variables
5. Parameters synchronized/created
6. Version automatically created
7. User redirected with success message

### Prompt Rendering Flow

1. Host app calls `ActivePrompt.render(:name, variables: {})`
2. Engine loads active prompt by name
3. Parameters validated against schema
4. Variables type-cast and substituted
5. Rendered content returned to caller

### Version Control Flow

1. User modifies prompt content/system message
2. Before save, current state captured
3. New version created with incremented number
4. Change description auto-generated
5. Version counter updated
6. Previous versions remain accessible

## Database Schema

### Tables

#### active_prompt_prompts
```sql
- id: bigint primary key
- name: string unique not null
- description: text
- content: text not null
- system_message: text
- model_config: jsonb default {}
- metadata: jsonb default {}
- status: integer default 0
- versions_count: integer default 0
- created_at: datetime
- updated_at: datetime
```

#### active_prompt_prompt_versions
```sql
- id: bigint primary key
- prompt_id: bigint foreign key
- version_number: integer not null
- content: text not null
- system_message: text
- model_config: jsonb
- change_description: string
- created_by: string
- created_at: datetime
```

#### active_prompt_parameters
```sql
- id: bigint primary key
- prompt_id: bigint foreign key
- name: string not null
- description: text
- parameter_type: integer default 0
- required: boolean default false
- default_value: string
- validation_rules: jsonb default {}
- position: integer
- created_at: datetime
- updated_at: datetime
```

### Indexes

- `prompts`: name (unique), status
- `versions`: [prompt_id, version_number]
- `parameters`: [prompt_id, name], [prompt_id, position]

## API Design

### Public Interface

```ruby
# Render a prompt
ActivePrompt.render(:welcome_email, variables: {
  user_name: "John",
  product: "SaaS App"
})

# Configure providers
ActivePrompt.configure do |config|
  config.anthropic_api_key = "..."
  config.openai_api_key = "..."
end
```

### Internal APIs

#### Prompt Retrieval
```ruby
prompt = ActivePrompt::Prompt.active.find_by!(name: "welcome_email")
```

#### Version Management
```ruby
prompt.versions.create!(change_description: "Updated tone")
prompt.restore_version!(version_number: 3)
```

#### Parameter Handling
```ruby
prompt.sync_parameters!
prompt.validate_variables(provided_variables)
```

## Security Considerations

### Authentication & Authorization
- Engine assumes host app handles authentication
- No built-in user management
- Relies on host app's admin area protection

### API Key Management
- Keys stored in Rails credentials
- Never exposed in UI
- Validated before provider initialization

### Input Validation
- Strong parameters in controllers
- Type validation for parameters
- SQL injection prevention via ActiveRecord
- XSS protection in views

## Performance Optimizations

### Database
- Indexed lookups on prompt names
- Counter caches for versions
- Efficient version ordering

### Caching Strategy
- Prompt rendering cacheable by host app
- Version history pagination
- Parameter validation results

### Asset Pipeline
- Propshaft for fast asset serving
- Minimal JavaScript (Stimulus where needed)
- CSS organized by component

## Testing Architecture

### Test Coverage

```
spec/
├── models/
│   ├── prompt_spec.rb
│   ├── prompt_version_spec.rb
│   └── parameter_spec.rb
├── controllers/
│   ├── prompts_controller_spec.rb
│   └── playground_controller_spec.rb
├── services/
│   ├── variable_detector_spec.rb
│   └── playground_executor_spec.rb
├── system/
│   ├── prompt_management_spec.rb
│   └── playground_spec.rb
└── dummy/
    └── # Test Rails app
```

### Testing Approach
- Unit tests for models and services
- Controller specs for request handling
- System specs for user workflows
- VCR for external API calls

## Development Workflow

### Local Development
```bash
# Setup
bundle install
cd spec/dummy
rails db:create db:migrate db:seed

# Run server
rails s

# Run tests
bundle exec rspec
```

### Engine Development
- Make changes in main engine directory
- Test in dummy app
- Run full test suite
- Update documentation

## Integration Guide

### Basic Integration

```ruby
# Gemfile
gem 'active_prompt'

# routes.rb
mount ActivePrompt::Engine => "/admin/prompts"

# In your code
result = ActivePrompt.render(:email_template, 
  variables: { name: "User" }
)
```

### Advanced Integration

```ruby
# Custom configuration
ActivePrompt.configure do |config|
  config.default_model = "gpt-4o"
  config.default_temperature = 0.7
end

# Async rendering (planned)
ActivePrompt.render_async(:prompt_name, 
  variables: {},
  callback: ->(result) { process_result(result) }
)
```

## Future Architecture

### Planned Components

#### Analytics System
- Usage tracking per prompt
- Cost calculation
- Performance metrics
- A/B testing support

#### Evaluation Framework
- Test case management
- Bulk testing interface
- Quality scoring
- Regression detection

#### Advanced API
- REST endpoints
- GraphQL support
- Webhook notifications
- Rate limiting

#### Template System
- Reusable components
- Template inheritance
- Partial rendering
- Template library

## Deployment Considerations

### Requirements
- Rails 8.0.2+
- Ruby 3.0+
- Database with JSON support
- Redis (for planned features)

### Configuration
- Environment-specific API keys
- Database connection pooling
- Asset precompilation
- Migration management

### Monitoring
- Prompt usage metrics
- API call tracking
- Error rate monitoring
- Performance tracking

## Conclusion

ActivePrompt provides a robust, extensible architecture for AI prompt management within Rails applications. Its modular design, comprehensive testing, and focus on developer experience make it suitable for teams looking to centralize and optimize their AI prompt workflows. The engine's architecture supports both current features and planned enhancements while maintaining Rails best practices and conventions.