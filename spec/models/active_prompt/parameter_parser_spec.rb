require 'rails_helper'

RSpec.describe ActivePrompt::ParameterParser, type: :model do
  describe "#initialize" do
    it "initializes with content" do
      parser = described_class.new("Hello {{name}}")
      expect(parser.content).to eq("Hello {{name}}")
    end
  end

  describe "#extract_parameters" do
    context "with parameters in content" do
      it "extracts single parameter" do
        parser = described_class.new("Hello {{name}}")
        parameters = parser.extract_parameters

        expect(parameters).to eq([
          {
            name: "name",
            placeholder: "{{name}}",
            required: true
          }
        ])
      end

      it "extracts multiple parameters" do
        parser = described_class.new("Hello {{name}}, welcome to {{city}} in {{country}}")
        parameters = parser.extract_parameters

        expect(parameters).to eq([
          { name: "name", placeholder: "{{name}}", required: true },
          { name: "city", placeholder: "{{city}}", required: true },
          { name: "country", placeholder: "{{country}}", required: true }
        ])
      end

      it "handles parameters with spaces inside braces" do
        parser = described_class.new("Hello {{ name }} from {{ location }}")
        parameters = parser.extract_parameters

        expect(parameters).to eq([
          { name: "name", placeholder: "{{name}}", required: true },
          { name: "location", placeholder: "{{location}}", required: true }
        ])
      end

      it "removes duplicate parameters" do
        parser = described_class.new("{{greeting}} there! {{greeting}} again! How is {{weather}}?")
        parameters = parser.extract_parameters

        expect(parameters).to eq([
          { name: "greeting", placeholder: "{{greeting}}", required: true },
          { name: "weather", placeholder: "{{weather}}", required: true }
        ])
      end

      it "handles parameters with underscores" do
        parser = described_class.new("The {{user_name}} has {{total_count}} items")
        parameters = parser.extract_parameters

        expect(parameters).to eq([
          { name: "user_name", placeholder: "{{user_name}}", required: true },
          { name: "total_count", placeholder: "{{total_count}}", required: true }
        ])
      end

      it "handles parameters with hyphens" do
        parser = described_class.new("{{first-name}} {{last-name}}")
        parameters = parser.extract_parameters

        expect(parameters).to eq([
          { name: "first-name", placeholder: "{{first-name}}", required: true },
          { name: "last-name", placeholder: "{{last-name}}", required: true }
        ])
      end

      it "handles parameters with numbers" do
        parser = described_class.new("{{item1}} and {{item2}}")
        parameters = parser.extract_parameters

        expect(parameters).to eq([
          { name: "item1", placeholder: "{{item1}}", required: true },
          { name: "item2", placeholder: "{{item2}}", required: true }
        ])
      end
    end

    context "without parameters" do
      it "returns empty array for plain text" do
        parser = described_class.new("Hello world!")
        expect(parser.extract_parameters).to eq([])
      end

      it "returns empty array for empty content" do
        parser = described_class.new("")
        expect(parser.extract_parameters).to eq([])
      end

      it "returns empty array for nil content" do
        parser = described_class.new(nil)
        expect(parser.extract_parameters).to eq([])
      end

      it "ignores single braces" do
        parser = described_class.new("Use {this} notation")
        expect(parser.extract_parameters).to eq([])
      end

      it "extracts parameters from incomplete double braces" do
        parser = described_class.new("Missing {{ closing or opening }}")
        # The regex will match "{{ closing or opening }}"
        expect(parser.extract_parameters).to eq([
          { name: "closing or opening", placeholder: "{{closing or opening}}", required: true }
        ])
      end
    end

    context "with edge cases" do
      it "does not extract empty parameter names" do
        parser = described_class.new("Hello {{}} world")
        parameters = parser.extract_parameters
        
        # The regex [^}]+ requires at least one character that's not a closing brace
        expect(parameters).to eq([])
      end

      it "handles nested braces incorrectly (known limitation)" do
        parser = described_class.new("{{outer {{inner}} text}}")
        parameters = parser.extract_parameters

        # Due to regex limitations, this will only capture up to the first closing braces
        expect(parameters).to eq([
          { name: "outer {{inner", placeholder: "{{outer {{inner}}", required: true }
        ])
      end

      it "handles special characters inside parameters" do
        parser = described_class.new("{{email@address}} and {{price$amount}}")
        parameters = parser.extract_parameters

        expect(parameters).to eq([
          { name: "email@address", placeholder: "{{email@address}}", required: true },
          { name: "price$amount", placeholder: "{{price$amount}}", required: true }
        ])
      end
    end
  end

  describe "#replace_parameters" do
    let(:parser) { described_class.new("Hello {{name}}, welcome to {{city}}!") }

    context "with matching parameters" do
      it "replaces all provided parameters" do
        result = parser.replace_parameters({
          "name" => "Alice",
          "city" => "New York"
        })

        expect(result).to eq("Hello Alice, welcome to New York!")
      end

      it "accepts string keys" do
        result = parser.replace_parameters({
          "name" => "Bob",
          "city" => "London"
        })

        expect(result).to eq("Hello Bob, welcome to London!")
      end

      it "accepts symbol keys" do
        result = parser.replace_parameters({
          name: "Charlie",
          city: "Paris"
        })

        expect(result).to eq("Hello Charlie, welcome to Paris!")
      end

      it "converts non-string values to strings" do
        result = parser.replace_parameters({
          "name" => 123,
          "city" => true
        })

        expect(result).to eq("Hello 123, welcome to true!")
      end

      it "handles nil values" do
        result = parser.replace_parameters({
          "name" => nil,
          "city" => "Tokyo"
        })

        expect(result).to eq("Hello , welcome to Tokyo!")
      end
    end

    context "with partial parameters" do
      it "replaces only provided parameters" do
        result = parser.replace_parameters({
          "name" => "David"
        })

        expect(result).to eq("Hello David, welcome to {{city}}!")
      end

      it "handles empty parameters hash" do
        result = parser.replace_parameters({})

        expect(result).to eq("Hello {{name}}, welcome to {{city}}!")
      end

      it "handles nil parameters" do
        result = parser.replace_parameters(nil)

        expect(result).to eq("Hello {{name}}, welcome to {{city}}!")
      end
    end

    context "with extra parameters" do
      it "ignores parameters not in content" do
        result = parser.replace_parameters({
          "name" => "Eve",
          "city" => "Berlin",
          "country" => "Germany",
          "age" => 25
        })

        expect(result).to eq("Hello Eve, welcome to Berlin!")
      end
    end

    context "with repeated parameters" do
      let(:parser) { described_class.new("{{item}} and {{item}} and {{item}}") }

      it "replaces all occurrences" do
        result = parser.replace_parameters({
          "item" => "apple"
        })

        expect(result).to eq("apple and apple and apple")
      end
    end

    context "with parameters containing spaces" do
      let(:parser) { described_class.new("{{ name }} lives in {{ city }}") }

      it "replaces parameters without spaces in keys" do
        result = parser.replace_parameters({
          "name" => "Frank",
          "city" => "Madrid"
        })

        expect(result).to eq("{{ name }} lives in {{ city }}")
      end

      it "requires exact match including spaces" do
        result = parser.replace_parameters({
          " name " => "Frank",
          " city " => "Madrid"
        })

        expect(result).to eq("Frank lives in Madrid")
      end
    end

    context "with special content" do
      it "preserves original content structure" do
        parser = described_class.new("Line 1\n{{param1}}\n\nLine 3 with {{param2}}")
        result = parser.replace_parameters({
          "param1" => "First",
          "param2" => "Second"
        })

        expect(result).to eq("Line 1\nFirst\n\nLine 3 with Second")
      end

      it "handles content with special regex characters" do
        parser = described_class.new("Price is ${{amount}} ({{currency}})")
        result = parser.replace_parameters({
          "amount" => "99.99",
          "currency" => "USD"
        })

        expect(result).to eq("Price is $99.99 (USD)")
      end
    end
  end

  describe "#has_parameters?" do
    context "with parameters" do
      it "returns true for single parameter" do
        parser = described_class.new("Hello {{name}}")
        expect(parser.has_parameters?).to be true
      end

      it "returns true for multiple parameters" do
        parser = described_class.new("{{greeting}} {{name}}")
        expect(parser.has_parameters?).to be true
      end
    end

    context "without parameters" do
      it "returns false for plain text" do
        parser = described_class.new("Hello world")
        expect(parser.has_parameters?).to be false
      end

      it "returns false for empty content" do
        parser = described_class.new("")
        expect(parser.has_parameters?).to be false
      end

      it "returns false for nil content" do
        parser = described_class.new(nil)
        expect(parser.has_parameters?).to be false
      end
    end
  end
end