# Practical Eval Testing with Contains Text Grader

## Overview

Since the JSON Schema grader has implementation issues, let's use the "Contains Text" grader to effectively test your business analyst prompt. This approach is actually more practical for many real-world scenarios where you want to ensure specific information appears in the output.

## Setting Up Your Business Analyst Prompt

### Step 1: Create the Prompt

```
Name: Business Competitor Analysis
Slug: business-competitor-analysis
Content: |
  You are a diligent and methodical business analyst with access to real-time internet search.
  Your role is to research and return structured, accurate, and up-to-date information on the competitive landscape for <company>{{company}}</company>.
  
  Please provide:
  1. THREE main competitors with their market positioning
  2. Key differentiation factors for the company
  3. Comparative market share information if available
  
  Format your response clearly with sections for:
  - Main Competitors (list 3 with brief descriptions)
  - Differentiation (what makes {{company}} unique)
  
  Be objective. Use reputable sources. Be concise but thorough.

System Message: You are a business analyst with expertise in competitive intelligence and market research. Provide factual, well-researched information.
Model: gpt-4o
Temperature: 0.3
Max Tokens: 2000
```

## Creating Effective Evaluation Sets

### Evaluation Set 1: Competitor Identification

**Name**: "Tech Giants - Competitor Recognition"  
**Grader Type**: Contains Text  
**Description**: "Verifies that well-known competitors are mentioned for major tech companies"

**Test Cases**:

1. **Tesla Competitors**
   - Input: `{ "company": "Tesla" }`
   - Expected Output Contains: `Ford`
   - Description: "Should mention Ford as a competitor"

2. **Tesla Competitors - GM**
   - Input: `{ "company": "Tesla" }`
   - Expected Output Contains: `General Motors`
   - Description: "Should mention GM or General Motors"

3. **Tesla Competitors - VW**
   - Input: `{ "company": "Tesla" }`
   - Expected Output Contains: `Volkswagen`
   - Description: "Should mention Volkswagen or VW"

4. **Apple Competitors**
   - Input: `{ "company": "Apple" }`
   - Expected Output Contains: `Samsung`
   - Description: "Should mention Samsung as a competitor"

5. **Netflix Competitors**
   - Input: `{ "company": "Netflix" }`
   - Expected Output Contains: `Disney`
   - Description: "Should mention Disney/Disney+ as a competitor"

### Evaluation Set 2: Industry-Specific Keywords

**Name**: "Industry Terminology"  
**Grader Type**: Contains Text  
**Description**: "Ensures industry-specific terms are used appropriately"

**Test Cases**:

1. **EV Industry Terms**
   - Input: `{ "company": "Tesla" }`
   - Expected Output Contains: `electric vehicle`
   - Description: "Should mention electric vehicles or EVs"

2. **Streaming Industry Terms**
   - Input: `{ "company": "Netflix" }`
   - Expected Output Contains: `streaming`
   - Description: "Should use streaming terminology"

3. **E-commerce Terms**
   - Input: `{ "company": "Amazon" }`
   - Expected Output Contains: `e-commerce`
   - Description: "Should mention e-commerce or online retail"

### Evaluation Set 3: Differentiation Analysis

**Name**: "Unique Value Propositions"  
**Grader Type**: Contains Text  
**Description**: "Verifies that key differentiators are mentioned"

**Test Cases**:

1. **Tesla Innovation**
   - Input: `{ "company": "Tesla" }`
   - Expected Output Contains: `Autopilot`
   - Description: "Should mention Autopilot or self-driving capabilities"

2. **Apple Ecosystem**
   - Input: `{ "company": "Apple" }`
   - Expected Output Contains: `ecosystem`
   - Description: "Should mention Apple's integrated ecosystem"

3. **Amazon Logistics**
   - Input: `{ "company": "Amazon" }`
   - Expected Output Contains: `Prime`
   - Description: "Should mention Prime delivery advantage"

## Advanced Testing Strategies

### 1. Create Comprehensive Test Suites

For thorough testing, create multiple test cases per company:

```
Tesla Test Suite:
- Contains "Ford" OR "F-150" (competitor product)
- Contains "General Motors" OR "GM" OR "Chevrolet"
- Contains "Volkswagen" OR "VW" OR "ID.4"
- Contains "charging network" (infrastructure differentiation)
- Contains "Autopilot" OR "Full Self-Driving" (tech differentiation)
- Contains "direct sales" OR "dealership" (business model)
```

### 2. Test Edge Cases

Create test cases for:
- Newer companies: `{ "company": "Rivian" }`
- Non-US companies: `{ "company": "BYD" }`
- B2B companies: `{ "company": "Salesforce" }`
- Niche players: `{ "company": "Peloton" }`

### 3. Version Comparison Testing

Create two versions of your prompt:

**Version 1** (Current): Your existing prompt
**Version 2** (Enhanced): Add more specific instructions

```diff
+ Please ensure you mention specific product names and market positions.
+ Include at least one quantitative metric (market share, revenue, users) if available.
```

Run the same test suite against both versions to see improvements.

## Setting Up Regular Expression Tests

If you want more flexible matching, use the Regex grader:

### Evaluation Set: Flexible Competitor Matching

**Name**: "Competitor Names - Flexible"  
**Grader Type**: Regular Expression  
**Grader Config Pattern**: `(Ford|F-150|General Motors|GM|Chevrolet|Volkswagen|VW|Toyota|BYD)`

This will match any of these competitor names or their variants.

## Practical Testing Workflow

### Phase 1: Baseline Testing
1. Create the prompt
2. Set up "Contains Text" eval set with 10-15 test cases
3. Run evaluation to establish baseline
4. Review failures to understand gaps

### Phase 2: Prompt Refinement
1. Identify patterns in failures
2. Update prompt with more specific instructions
3. Create new version
4. Run same eval set on new version
5. Compare results

### Phase 3: Expanded Testing
1. Add more test cases for edge scenarios
2. Create industry-specific eval sets
3. Test with 20-30 companies across industries

## Example Test Results Analysis

After running your evaluations, you might see:

```
Evaluation: Tech Giants - Competitor Recognition
Total: 15 tests
Passed: 12
Failed: 3
Success Rate: 80%

Failed Tests:
1. "Rivian" - Did not mention Tesla as competitor
2. "Palantir" - Did not mention Databricks
3. "Zoom" - Did not mention Microsoft Teams

Action Items:
- Add instruction to include market leaders even for smaller companies
- Specify to mention both direct and indirect competitors
```

## Benefits of Contains Text Approach

1. **Simplicity**: Easy to set up and understand
2. **Flexibility**: Can test for any specific content
3. **Interpretability**: Clear why tests pass or fail
4. **Iterative**: Easy to add new test cases
5. **Practical**: Focuses on actual content quality

## Quick Start Checklist

- [ ] Create prompt with {{company}} variable
- [ ] Create eval set "Competitor Recognition"
- [ ] Add 5 test cases for well-known companies
- [ ] Run evaluation
- [ ] Review results and identify patterns
- [ ] Refine prompt based on failures
- [ ] Create new version and re-test
- [ ] Expand test suite with edge cases

## Next Steps

1. Start with 5-10 simple "Contains Text" test cases
2. Focus on obvious competitors that should always be mentioned
3. Gradually add more sophisticated tests
4. Use results to iteratively improve your prompt
5. Once stable, create specialized eval sets for different industries

This approach will give you immediate, actionable feedback on your prompt's performance without dealing with complex JSON validation issues.