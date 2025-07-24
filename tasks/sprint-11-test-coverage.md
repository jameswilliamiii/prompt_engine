# Sprint 11: Test Coverage Improvement

**Sprint Goal**: Improve test coverage from 47.7% to 70%+ by writing critical missing tests

**Duration**: 1 day
**Priority**: High

## Current Status
- Line Coverage: 47.7% (218 / 457)
- Branch Coverage: 29.7% (30 / 101)

## Sprint Tasks

### 1. Service Layer Tests (Agent: Service Tester)
**Priority**: HIGHEST - Currently 0% coverage

- [ ] PlaygroundExecutor Service
  - Test successful execution with Anthropic provider
  - Test successful execution with OpenAI provider
  - Test API client initialization
  - Test error handling (network, rate limits, invalid keys)
  - Test parameter substitution
  - Test response formatting
  - Test model configuration application

- [ ] ParameterParser Model/Service
  - Test parsing parameters from prompt content
  - Test handling various parameter formats
  - Test invalid syntax detection
  - Test edge cases (empty, special chars)

### 2. Model Tests (Agent: Model Tester)
**Priority**: HIGH - Critical missing coverage

- [ ] Parameter Model
  - Test all validations
  - Test type casting for all parameter types
  - Test default value handling
  - Test associations
  - Test form input generation
  - Test value validation against constraints

- [ ] Prompt Model (additional methods)
  - Test render method with various parameters
  - Test sync_parameters! method
  - Test parameter-related methods
  - Test scopes and complex queries

### 3. Controller/Request Tests (Agent: Controller Tester)
**Priority**: MEDIUM-HIGH - Currently 0% coverage

- [ ] PlaygroundController
  - Test show action
  - Test execute action success
  - Test execute action with errors
  - Test parameter validation
  - Test different response formats

- [ ] Additional PromptsController tests
  - Test playground action
  - Test test action
  - Test duplicate action
  - Test search functionality

### 4. Integration Tests (Agent: Integration Tester)
**Priority**: MEDIUM

- [ ] Full prompt lifecycle test
- [ ] Playground execution with mocked API
- [ ] Version management workflow
- [ ] Parameter detection and sync workflow

## Success Criteria
- Line coverage reaches 70%+
- All service classes have tests
- Parameter model fully tested
- PlaygroundController has basic coverage
- No test failures introduced

## Testing Guidelines
- Follow conventions in .ai/RSPEC-TESTS.md
- Use FactoryBot for test data
- Mock external API calls with VCR/WebMock
- Write explicit, active expectations
- Test both happy and unhappy paths
- One expectation per unit test
- Use request specs for controllers

## Agent Assignments

1. **Service Tester Agent**: Focus on PlaygroundExecutor and ParameterParser
2. **Model Tester Agent**: Focus on Parameter model and additional Prompt model methods
3. **Controller Tester Agent**: Focus on PlaygroundController and additional controller actions
4. **Integration Tester Agent**: Focus on end-to-end workflows

Each agent should:
- Read the relevant source files
- Write comprehensive tests following best practices
- Run tests to ensure they pass
- Achieve high coverage for their assigned area