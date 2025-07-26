# Testing Business Analysis Prompts with OpenAI Evals

## Overview

Your business analyst prompt is an excellent candidate for evaluation testing because it:
1. Has structured output requirements (JSON format)
2. Contains verifiable facts (competitor names, market positioning)
3. Has quality criteria (accuracy, completeness, objectivity)
4. Can be tested with different companies for consistency

## Setting Up Eval Tests in PromptEngine

### Step 1: Create Your Prompt in PromptEngine

First, create your business analyst prompt:

```ruby
# In the PromptEngine admin interface:
Name: Business Competitor Analysis
Slug: business-competitor-analysis
Content: |
  You are a diligent and methodical business analyst with access to real-time internet search.
  Your role is to research and return structured, accurate, and up-to-date information on the competitive landscape for <company>{{company}}</company>.
  Please structure your research as a JSON object using the following keys:

  {
    "CompetitorAnalysis": {
      label: "Competitor Analysis",
      value: {
        "MainCompetitors": {
          value: "Identify and profile three main competitors, including their strengths, market positioning, and comparative market share",
          label: "Main Competitors"
        },
        "Differentiation": {
          value: "Detailed analysis of what differentiates the company from these competitors, including unique offerings, technology, approach, or market positioning",
          label: "Differentiation"
        }
      }
    }
  }

  If there is no information for one of these fields, concepts or properties, fill in a nil into the value key.

  Be objective. Use reputable sources. Avoid speculative claims.

  Return only valid JSON output. Do not include any introductory or closing remarks.

System Message: You are a business analyst with expertise in competitive intelligence and market research.
Model: gpt-4o
Temperature: 0.3  # Lower temperature for more consistent, factual outputs
Max Tokens: 2000
```

### Step 2: Create Evaluation Sets with Different Grader Types

#### Evaluation Set 1: JSON Structure Validation

**Name**: "JSON Format Compliance"  
**Grader Type**: JSON Schema  
**Purpose**: Ensure outputs are valid JSON with required structure

**Grader Config**:
```json
{
  "schema": {
    "type": "object",
    "required": ["CompetitorAnalysis"],
    "properties": {
      "CompetitorAnalysis": {
        "type": "object",
        "required": ["label", "value"],
        "properties": {
          "label": { "type": "string" },
          "value": {
            "type": "object",
            "required": ["MainCompetitors", "Differentiation"],
            "properties": {
              "MainCompetitors": {
                "type": "object",
                "required": ["value", "label"],
                "properties": {
                  "value": { "type": ["string", "null"] },
                  "label": { "type": "string" }
                }
              },
              "Differentiation": {
                "type": "object",
                "required": ["value", "label"],
                "properties": {
                  "value": { "type": ["string", "null"] },
                  "label": { "type": "string" }
                }
              }
            }
          }
        }
      }
    }
  }
}
```

**Test Cases**:
1. **Input**: `{ "company": "Tesla" }`  
   **Expected**: Valid JSON matching schema

2. **Input**: `{ "company": "Apple" }`  
   **Expected**: Valid JSON matching schema

3. **Input**: `{ "company": "OpenAI" }`  
   **Expected**: Valid JSON matching schema

#### Evaluation Set 2: Content Quality - Contains Key Information

**Name**: "Competitor Identification"  
**Grader Type**: Contains Text  
**Purpose**: Verify that actual competitor names are mentioned

**Test Cases**:
1. **Input**: `{ "company": "Tesla" }`  
   **Expected Output Should Contain**: One of: "Ford", "GM", "General Motors", "Volkswagen", "Toyota", "BYD", "Rivian", "Lucid"
   
2. **Input**: `{ "company": "Netflix" }`  
   **Expected Output Should Contain**: One of: "Disney", "Amazon Prime", "HBO", "Hulu", "Apple TV", "Paramount"

3. **Input**: `{ "company": "Uber" }`  
   **Expected Output Should Contain**: One of: "Lyft", "DoorDash", "Grab", "Didi"

#### Evaluation Set 3: Factual Accuracy with Regex

**Name**: "Market Leader Recognition"  
**Grader Type**: Regular Expression  
**Purpose**: Ensure major competitors are properly identified

**Grader Config**:
```json
{
  "pattern": "(Ford|GM|General Motors|Volkswagen|Toyota|BYD|Stellantis|Mercedes|BMW)",
  "flags": "i"
}
```

**Test Cases**:
1. **Input**: `{ "company": "Tesla" }`  
   **Expected**: Match (should mention at least one major auto manufacturer)

2. **Input**: `{ "company": "Rivian" }`  
   **Expected**: Match (should mention established automakers)

### Step 3: Advanced Evaluation Scenarios

#### A/B Testing Different Temperatures

Create two versions of your prompt with different temperatures:
- Version 1: Temperature 0.3 (more consistent, factual)
- Version 2: Temperature 0.7 (more creative, detailed)

Run the same test cases against both versions to see which produces:
- More accurate competitor identification
- Better differentiation analysis
- More consistent JSON formatting

#### Testing Different System Messages

Create variants with different system messages:

**Variant A**: "You are a business analyst with expertise in competitive intelligence and market research."

**Variant B**: "You are a senior strategy consultant at a top-tier firm specializing in competitive analysis. Focus on actionable insights and strategic positioning."

**Variant C**: "You are a market research expert. Prioritize data accuracy and cite specific market share percentages when available."

### Step 4: Sample Test Implementation

Here's how to implement comprehensive testing:

```ruby
# Create a comprehensive test suite
test_companies = [
  # Tech Giants
  { company: "Apple", expected_competitors: ["Samsung", "Google", "Microsoft"] },
  { company: "Google", expected_competitors: ["Microsoft", "Apple", "Amazon"] },
  
  # E-commerce
  { company: "Amazon", expected_competitors: ["Walmart", "Alibaba", "eBay"] },
  { company: "Shopify", expected_competitors: ["WooCommerce", "BigCommerce", "Square"] },
  
  # Automotive
  { company: "Tesla", expected_competitors: ["Ford", "GM", "Volkswagen", "BYD"] },
  { company: "Ford", expected_competitors: ["GM", "Toyota", "Stellantis"] },
  
  # Streaming
  { company: "Netflix", expected_competitors: ["Disney", "Amazon", "HBO"] },
  { company: "Spotify", expected_competitors: ["Apple Music", "Amazon Music", "YouTube Music"] },
  
  # Rideshare
  { company: "Uber", expected_competitors: ["Lyft", "DoorDash", "Bolt"] },
  { company: "DoorDash", expected_competitors: ["Uber Eats", "Grubhub", "Postmates"] }
]
```

### Step 5: Quality Metrics to Track

1. **JSON Validity Rate**: Percentage of outputs that are valid JSON
2. **Schema Compliance**: Percentage matching the exact schema
3. **Competitor Accuracy**: Percentage correctly identifying major competitors
4. **Null Handling**: Proper use of null values when information unavailable
5. **Response Consistency**: Similar companies getting similar quality responses

### Step 6: Creating a Prompt Improvement Workflow

1. **Baseline Testing**: Run initial eval set with 20-30 test cases
2. **Identify Failures**: Look for patterns in failed tests
3. **Iterate on Prompt**: Adjust based on failure patterns
4. **Re-test**: Run same eval set on new version
5. **Compare Results**: Use PromptEngine's version comparison

#### Common Issues and Fixes:

**Issue**: Inconsistent JSON formatting  
**Fix**: Add explicit JSON formatting instructions: "Ensure all JSON keys use double quotes"

**Issue**: Missing competitors  
**Fix**: Add guidance: "Always identify exactly three competitors, even if one is significantly smaller"

**Issue**: Too verbose  
**Fix**: Add constraint: "Keep each analysis section under 150 words"

### Step 7: Production Readiness Checklist

Before deploying your prompt:

- [ ] 90%+ pass rate on JSON structure tests
- [ ] 80%+ accuracy on competitor identification
- [ ] Consistent performance across diverse company types
- [ ] Handles edge cases (small companies, new industries)
- [ ] Response time within acceptable limits
- [ ] Cost per query within budget

### Example Eval Run Results

After running evaluations, you might see:

```
Evaluation Set: JSON Format Compliance
Total Tests: 30
Passed: 28
Failed: 2
Success Rate: 93.3%

Evaluation Set: Competitor Identification  
Total Tests: 30
Passed: 24
Failed: 6
Success Rate: 80%

Common Failures:
- Emerging companies (failed to identify competitors)
- Non-English company names (parsing issues)
```

### Best Practices for Business Analysis Evals

1. **Use Real Companies**: Test with actual companies for realistic results
2. **Include Edge Cases**: Small startups, non-US companies, conglomerates
3. **Version Everything**: Track prompt changes with detailed notes
4. **Regular Re-evaluation**: Markets change, re-run evals quarterly
5. **Human Review**: Periodically manually review outputs for quality

### Next Steps

1. Start with the JSON structure eval set - it's the easiest to implement
2. Build a corpus of 20-30 test companies across industries
3. Run baseline evaluation
4. Iterate on the prompt based on results
5. Add more sophisticated evals as you refine the prompt

This structured approach will help you systematically improve your business analysis prompt while maintaining quality and consistency.