# Required Changes to Align with Stimulus Conventions (Minimal Approach)

This document outlines the essential changes needed to align the PromptEngine Rails engine with the updated Stimulus conventions, while keeping the current full-page-load approach for forms.

## 1. JavaScript Architecture (REQUIRED for Host App Integration)

### Create Missing JavaScript Structure
```
app/javascript/prompt_engine/
├── index.js                              # Main entry point
└── controllers/
    ├── prompt_form_controller.js         # Slug generation & variable detection
    ├── variable_detector_controller.js   # Parameter management
    └── modal_controller.js               # Modal functionality (if needed)
```

**Current State**: No JavaScript files exist at all. All functionality is implemented as inline scripts.

**Required Actions**:
- Create `app/javascript/prompt_engine/` directory structure
- Move inline JavaScript from views into proper Stimulus controllers
- Implement controllers with proper prefixes: `prompt-engine--*`
- Create main `index.js` with `registerControllers()` function for host app integration
- **Keep existing form behavior** - no need for AJAX conversion

### Replace Inline JavaScript

**Files with inline JavaScript that need conversion**:
1. `app/views/prompt_engine/playground/show.html.erb` (lines 99-129) - **API key provider switching**
2. `app/views/prompt_engine/prompts/_form.html.erb` (lines 117-254) - **Slug generation + variable detection**

**Required Actions**:
- Extract all inline `<script>` tags to proper Stimulus controllers  
- Convert existing functionality to Stimulus methods (no behavior changes)
- Use proper `prompt-engine--*` controller names and Stimulus targets
- Remove all `<script>` tags from view templates

## 2. Engine Configuration (MISSING)

### Update `lib/prompt_engine/engine.rb`

**Missing Configurations**:
```ruby
# Add JavaScript path to asset pipeline
initializer "prompt_engine.asset_paths" do |app|
  app.config.assets.paths << root.join("app/javascript")
end

# Sprockets-only: ensure engine CSS is precompiled when host uses Sprockets
initializer "prompt_engine.assets.precompile" do |app|
  app.config.assets.precompile += %w[
    prompt_engine/application.css
  ]
end
```

**Current State**: Engine has no JavaScript asset configuration.

## 3. Controllers (NO CHANGES NEEDED)

**Current State**: Controllers work fine with full page loads.

**Decision**: Keep existing controller behavior:
- `PlaygroundController#execute` continues to `render :result` 
- `PromptsController` continues normal form submissions
- No JSON API changes needed
- No AJAX conversion required

This maintains simplicity while still achieving proper Stimulus integration.

## 4. View Template Updates (FOCUSED CHANGES)

### Playground View Update

**File**: `app/views/prompt_engine/playground/show.html.erb`

**Required Changes**:
- Remove `<script>` section (lines 99-129)
- Add Stimulus controller data attributes:
  ```erb
  <div data-controller="prompt-engine--playground">
  ```
- **Keep existing form behavior** - no need for `data-turbo="false"` or AJAX conversion
- Add Stimulus targets for API key field and provider select

### Prompt Form Update

**File**: `app/views/prompt_engine/prompts/_form.html.erb`

**Required Changes**:
- Remove `<script>` section (lines 117-254)  
- Add Stimulus controller data attributes:
  ```erb
  <div data-controller="prompt-engine--prompt-form prompt-engine--variable-detector">
  ```
- Update existing data attributes to use proper controller names:
  - `data-action="input->prompt-engine--prompt-form#generateSlug"`
  - `data-action="input->prompt-engine--variable-detector#detectVariables"`
- **Keep all existing form submission behavior** - no AJAX needed

## 5. Install Generator (COMPLETELY MISSING)

### Create Generator Structure
```
lib/generators/prompt_engine/install/
├── install_generator.rb
└── templates/
    └── initializer.rb
```

**Required Actions**:
- Create complete install generator following convention examples
- Handle Import Maps and bundler detection
- Automatic Stimulus controller registration
- CSS integration (Sprockets/Propshaft detection)
- Route mounting
- Migration installation guidance

### Generator Features Needed
- Route mounting: `mount PromptEngine::Engine => '/prompt_engine'`
- JavaScript integration (Import Maps or bundler)
- CSS inclusion
- API key setup guidance
- Post-install instructions

## 6. Routes Structure (NO CHANGES NEEDED)

**Current State**: Routes work fine as-is.

**Decision**: Keep existing route structure:
```ruby
get :playground, to: "playground#show"
post :playground, to: "playground#execute"
```

No need for RESTful changes since we're keeping the current controller behavior.

## 7. Testing Updates (MINIMAL)

Once JavaScript is implemented:
- Add basic system specs for Stimulus controllers (slug generation, variable detection)
- **No AJAX testing needed** since we're keeping full page loads
- Existing controller specs should continue working unchanged

## Implementation Priority

### Phase 1 (Essential)
1. Create JavaScript directory structure  
2. Update engine configuration for assets
3. Create install generator (critical for host app integration)

### Phase 2 (High Impact)  
1. Extract playground JavaScript to Stimulus controller (simple provider switching)
2. Extract prompt form JavaScript to Stimulus controllers (complex variable detection)
3. Update view templates to use proper Stimulus attributes

### Phase 3 (Optional)
1. Add basic system specs for JavaScript functionality
2. Look for any other inline JavaScript in views

## Breaking Changes Warning

**Minimal Breaking Changes**:
- Host applications will need to run the install generator to get JavaScript integration
- Views will lose JavaScript functionality until Stimulus controllers are implemented
- **No controller API changes** - existing integrations continue working

## Estimated Effort (Revised)

- **Engine Configuration & Install Generator**: 1-2 days
- **JavaScript Controllers**: 2-3 days (variable detection logic is complex)
- **View Template Updates**: 1 day (just removing `<script>` tags and adding data attributes)
- **Basic Testing**: 1 day

**Total Estimate**: 5-7 days of development time

**Key Simplification**: By keeping full page loads, we eliminate the most complex parts (AJAX conversion, JSON APIs, loading states) and focus only on proper Stimulus integration for host applications.