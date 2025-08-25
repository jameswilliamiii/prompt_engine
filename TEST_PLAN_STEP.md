# Test Plan for Stimulus Refactor

This document outlines the testing approach for each phase of converting PromptEngine from inline JavaScript to proper Stimulus controllers.

## Current Test Status Analysis

### ✅ Tests That Will Continue Working (No Changes Needed)
- **All model specs** - Pure Ruby logic, no JavaScript dependency
- **All service specs** - Including `VariableDetector` (backend logic only)
- **All request specs** - Testing controller endpoints, not JavaScript behavior
- **Most system specs** - Basic form submissions use `driven_by(:rack_test)` which bypasses JavaScript

### ❌ Tests That Will Break/Need Updates
**None identified yet!** 

**Key Finding**: The current system specs in `spec/system/prompts_spec.rb` use `driven_by(:rack_test)` which **doesn't execute JavaScript at all**. This means the inline `<script>` tags aren't actually being tested currently.

**Evidence**: Line 104-105 in prompts_spec.rb:
```ruby
# Note: rack_test doesn't support JavaScript, so we can't test dismissing confirm dialog
# The delete button would need JavaScript support to show confirm dialog
```

### 🔍 Tests That Need Investigation
- **Capybara screenshots in `/tmp/capybara/failures_*`** - Many failures suggest JavaScript features were expected but not working
- **System specs with `js: true`** - Need to check if any exist that specifically test JavaScript

## Phase-by-Phase Test Plan

### Phase 1: Engine Configuration & Install Generator
**Testing Focus**: Infrastructure setup

#### New Tests Needed (Minimal)
```ruby
# spec/lib/generators/prompt_engine/install/install_generator_spec.rb
RSpec.describe PromptEngine::Generators::InstallGenerator do
  it "adds engine route mount" do
    run_generator
    expect(File.read("config/routes.rb")).to include("mount PromptEngine::Engine")
  end
  
  it "adds importmap pin" do
    run_generator  
    expect(File.read("config/importmap.rb")).to include('pin "prompt_engine"')
  end
  
  it "adds javascript integration" do
    run_generator
    expect(File.read("app/javascript/application.js")).to include("registerControllers")
  end
end
```

#### Dummy App Updates Required
```ruby
# spec/dummy needs these additions:

# 1. config/importmap.rb (new file)
pin "application", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "prompt_engine", to: "prompt_engine/index.js"

# 2. app/javascript/application.js (new file) 
import "controllers"
import { application } from "controllers/application"
import { registerControllers } from "prompt_engine"
registerControllers(application)

# 3. app/javascript/controllers/application.js (new file)
import { Application } from "@hotwired/stimulus"
const application = Application.start()
export { application }

# 4. app/javascript/controllers/index.js (new file)
import { application } from "controllers/application"

# 5. Update app/views/layouts/application.html.erb
<%= javascript_importmap_tags %>  # Add this line
```

### Phase 2: Stimulus Controllers (High Risk Phase)
**Testing Focus**: JavaScript functionality conversion

#### Tests That Will Break During This Phase
**EXPECTED**: All Capybara screenshot failures will likely start passing once we implement proper Stimulus controllers, since the current inline JavaScript probably isn't working in tests.

#### New Tests Needed (Essential)
```ruby
# spec/system/prompt_engine/javascript_features_spec.rb  
RSpec.describe "JavaScript Features", type: :system, js: true do
  describe "Slug Generation" do
    it "auto-generates slug from prompt name" do
      visit "/prompt_engine/prompts/new"
      
      fill_in "Name", with: "Customer Support Bot"
      
      # Trigger the slug generation (Stimulus controller)
      find("body").click  # Trigger blur/change
      
      expect(find_field("Slug").value).to eq("customer-support-bot")
    end
    
    it "preserves manual slug edits after initial generation" do
      visit "/prompt_engine/prompts/new"
      
      fill_in "Name", with: "Test Prompt"
      find("body").click
      
      # Manually edit the slug
      fill_in "Slug", with: "custom-slug"
      
      # Change name again - should not overwrite manual slug
      fill_in "Name", with: "Updated Test Prompt"
      find("body").click
      
      expect(find_field("Slug").value).to eq("custom-slug")
    end
  end
  
  describe "Variable Detection and Parameter Management" do
    it "detects variables in prompt content and creates parameter fields" do
      visit "/prompt_engine/prompts/new"
      
      fill_in "Prompt Content", with: "Hello {{user_name}}, your balance is {{balance}}"
      
      # Should show parameters section
      expect(page).to have_css("#parameters-section", visible: true)
      expect(page).to have_content("user_name")
      expect(page).to have_content("balance")
      expect(page).to have_field("prompt[parameters_attributes][0][name]", with: "user_name")
      expect(page).to have_field("prompt[parameters_attributes][1][name]", with: "balance")
    end
    
    it "removes parameter fields when variables are deleted from content" do
      visit "/prompt_engine/prompts/new"
      
      fill_in "Prompt Content", with: "Hello {{user_name}}"
      expect(page).to have_content("user_name")
      
      # Remove the variable
      fill_in "Prompt Content", with: "Hello world"
      
      # Parameters section should be hidden
      expect(page).to have_css("#parameters-section", visible: false)
    end
    
    it "handles duplicate variables correctly" do
      visit "/prompt_engine/prompts/new"
      
      fill_in "Prompt Content", with: "{{name}} is {{name}} and {{name}} again"
      
      # Should only show one parameter field for 'name'
      name_fields = page.all("input[name*='[name]'][value='name']")
      expect(name_fields.count).to eq(1)
    end
    
    it "detects complex variable names with dots" do
      visit "/prompt_engine/prompts/new"
      
      fill_in "Prompt Content", with: "User: {{user.name}}, Email: {{user.email}}"
      
      expect(page).to have_content("user.name")
      expect(page).to have_content("user.email")
    end
  end
  
  describe "Editing Existing Prompt with Parameters" do
    let!(:prompt) { 
      create(:prompt, 
        name: "Test Prompt",
        content: "Hello {{name}}, welcome to {{company}}!"
      ).tap { |p| p.sync_parameters! }
    }
    
    it "loads existing parameters and preserves their settings" do
      # Set up existing parameter with custom settings
      prompt.parameters.find_by(name: "name").update!(
        description: "User's full name",
        parameter_type: "string",
        required: true,
        default_value: "Anonymous"
      )
      
      visit "/prompt_engine/prompts/#{prompt.id}/edit"
      
      expect(page).to have_content("name")
      expect(page).to have_content("company") 
      
      # Check that existing parameter settings are loaded
      within_fieldset_for_parameter("name") do
        expect(find_field("Description")).value).to eq("User's full name")
        expect(find_field("Type")).value).to eq("string")
        expect(find_field("Required")).to be_checked
        expect(find_field("Default Value")).value).to eq("Anonymous")
      end
    end
    
    it "updates parameters when content changes" do
      visit "/prompt_engine/prompts/#{prompt.id}/edit"
      
      # Add a new variable
      fill_in "Prompt Content", with: "Hello {{name}}, welcome to {{company}}! Your role is {{role}}."
      
      expect(page).to have_content("role")
      
      # Remove a variable  
      fill_in "Prompt Content", with: "Hello {{name}}! Your role is {{role}}."
      
      # company should be gone, but name and role should remain
      expect(page).to have_content("name")
      expect(page).to have_content("role")
      expect(page).not_to have_content("company")
    end
  end
  
  describe "Playground API Key Switching" do
    let!(:prompt) { create(:prompt) }
    
    it "updates API key field when provider changes" do
      visit "/prompt_engine/prompts/#{prompt.id}/playground"
      
      # Should start with no API key if no settings configured
      expect(find_field("API Key").value).to be_blank
      
      select "Anthropic", from: "AI Provider"
      # API key field should update (even if blank)
      expect(find_field("API Key")[:placeholder]).to include("Enter your API key")
      
      select "OpenAI", from: "AI Provider"
      expect(find_field("API Key")[:placeholder]).to include("Enter your API key")
    end
  end
end

def within_fieldset_for_parameter(param_name)
  within(find(".parameter-item", text: param_name)) do
    yield
  end
end
```

### Phase 3: View Template Updates
**Testing Focus**: Data attribute integration

#### Existing Tests to Monitor
All existing system specs should continue working since we're keeping the same form behavior.

#### Potential Issues to Watch For
- **CSS selectors** - If any tests rely on specific DOM structure that changes
- **Form submission behavior** - Should remain identical 
- **Flash messages** - Should work exactly the same

### Phase 4: Final Integration Testing
**Testing Focus**: End-to-end validation

#### Integration Tests (Optional)
```ruby
# spec/integration/stimulus_integration_spec.rb
RSpec.describe "Full Stimulus Integration", type: :system, js: true do
  it "creates a prompt with variables and tests it in playground" do
    visit "/prompt_engine/prompts/new"
    
    # Use Stimulus controllers for slug generation
    fill_in "Name", with: "User Greeting"
    expect(find_field("Slug").value).to eq("user-greeting")
    
    # Use Stimulus controllers for variable detection  
    fill_in "Prompt Content", with: "Hello {{user_name}}, welcome to {{platform}}!"
    
    expect(page).to have_content("user_name")
    expect(page).to have_content("platform")
    
    click_button "Create Prompt"
    
    # Should work with full page load (no AJAX)
    expect(page).to have_content("Prompt was successfully created")
    
    # Test playground (API key switching)
    click_link "Test"
    
    select "OpenAI", from: "AI Provider"
    expect(find_field("API Key")[:placeholder]).to include("Enter")
  end
end
```

## Test Execution Strategy

### Before Starting Each Phase
```bash
# Ensure all tests pass before making changes
bundle exec rspec --fail-fast

# Run specific test suites to establish baseline
bundle exec rspec spec/models/
bundle exec rspec spec/services/
bundle exec rspec spec/requests/
bundle exec rspec spec/system/prompts_spec.rb
```

### During Each Phase
```bash
# Skip failing JavaScript tests during development
bundle exec rspec --tag ~js

# When ready to test JavaScript functionality
bundle exec rspec --tag js spec/system/prompt_engine/javascript_features_spec.rb
```

### After Each Phase
```bash
# Full test suite should pass
bundle exec rspec

# Check coverage (should maintain or improve current coverage)
open coverage/index.html
```

## Testing Philosophy Notes

### ✅ What We're Testing
- **Stimulus controller functionality** - JavaScript behavior works correctly
- **Form integration** - Controllers properly connect to form elements
- **User interactions** - Real browser testing of dynamic features
- **Regression prevention** - Existing behavior is preserved

### ❌ What We're NOT Testing
- **Install generator edge cases** - Only basic functionality (Import Maps assumed)
- **Multiple JavaScript environments** - Only Import Maps support for now
- **Complex error scenarios** - Focus on happy path integration

### 🔄 Future Testing Improvements (Post-Refactor)
Add these to a future cleanup task:
- Simplify the complex variable detection tests 
- Consolidate duplicate test scenarios
- Add performance testing for large prompt content
- Test error handling in Stimulus controllers

## Dummy App Test Requirements

### Missing Dependencies (Need to Add)
```ruby
# spec/dummy/Gemfile (if exists, or main Gemfile)
# No new gems needed - Stimulus ships with Rails 8

# spec/dummy/config/application.rb updates
config.importmap.sweep_cache = true # For development reloading
```

### Directory Structure to Create
```
spec/dummy/app/javascript/
├── application.js
└── controllers/
    ├── application.js
    └── index.js
```

### Asset Configuration
The dummy app will need proper asset serving configuration for JavaScript in test environment - this should be handled automatically by Rails 8's defaults.

## Risk Assessment

### 🔴 High Risk
- **Variable detection logic** - Complex JavaScript with many edge cases
- **Parameter field management** - Dynamic DOM manipulation
- **Existing test stability** - Current JavaScript features may not be working in tests anyway

### 🟡 Medium Risk  
- **Dummy app JavaScript setup** - New territory for the test suite
- **Capybara + Stimulus integration** - Potential timing issues
- **Asset serving in tests** - JavaScript files need to load correctly

### 🟢 Low Risk
- **Basic form behavior** - No AJAX changes, same controller responses  
- **Model/service tests** - Pure Ruby, unaffected by JavaScript changes
- **Install generator** - Simple file modifications

## Success Criteria

### Phase 1 Complete When:
- [ ] Install generator tests pass
- [ ] Dummy app can serve JavaScript assets
- [ ] Engine configuration includes JavaScript paths

### Phase 2 Complete When: 
- [ ] All new JavaScript feature tests pass
- [ ] No inline `<script>` tags remain in views
- [ ] Existing non-JavaScript system specs still pass

### Phase 3 Complete When:
- [ ] All system specs pass (including JavaScript ones)
- [ ] Views use proper `data-controller` and Stimulus conventions
- [ ] Full form-to-playground workflow works end-to-end

### Overall Success When:
- [ ] `bundle exec rspec` passes completely
- [ ] Test coverage is maintained or improved  
- [ ] No breaking changes to existing functionality
- [ ] Host applications can integrate via install generator