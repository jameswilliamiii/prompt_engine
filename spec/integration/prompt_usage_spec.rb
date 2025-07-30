require "rails_helper"

RSpec.describe "Using prompts in Rails models", type: :integration do
  # Create a sample model in the dummy app that uses PromptEngine
  before(:all) do
    # Define a temporary model class for testing
    class ::CustomerEmail
      include ActiveModel::Model
      attr_accessor :customer_name, :product_name

      def generate_welcome_email
        PromptEngine.render("welcome-email",
          { customer_name: customer_name,
            product_name: product_name })

        # In a real app, this would call an AI service
        # For testing, we just return the rendered prompt
      end

      def generate_support_response(issue_description)
        PromptEngine.render("support-response",
          { customer_name: customer_name,
            issue: issue_description })
      end
    end
  end

  after(:all) do
    # Clean up the temporary class
    Object.send(:remove_const, :CustomerEmail) if defined?(::CustomerEmail)
  end

  describe "Creating and using prompts" do
    let!(:welcome_prompt) do
      PromptEngine::Prompt.create!(
        name: "welcome-email",
        content: "Write a welcome email for {{customer_name}} who just purchased {{product_name}}. Make it friendly and professional.",
        system_message: "You are a helpful customer service assistant.",
        model: "gpt-4",
        temperature: 0.7,
        max_tokens: 500,
        status: "active"
      )
    end

    let!(:support_prompt) do
      PromptEngine::Prompt.create!(
        name: "support-response",
        content: "Help {{customer_name}} with the following issue: {{issue}}",
        system_message: "You are a technical support specialist. Be helpful and concise.",
        model: "gpt-3.5-turbo",
        temperature: 0.3,
        max_tokens: 300,
        status: "active"
      )
    end

    it "allows a Rails model to render a prompt with variables" do
      customer = CustomerEmail.new(
        customer_name: "John Doe",
        product_name: "Premium Subscription"
      )

      result = customer.generate_welcome_email

      expect(result).to be_a(PromptEngine::RenderedPrompt)
      expect(result.content).to include("John Doe")
      expect(result.content).to include("Premium Subscription")
      expect(result.system_message).to eq("You are a helpful customer service assistant.")
      expect(result.model).to eq("gpt-4")
      expect(result.temperature).to eq(0.7)
      expect(result.max_tokens).to eq(500)
    end

    it "handles multiple prompts in the same model" do
      customer = CustomerEmail.new(customer_name: "Jane Smith")

      support_result = customer.generate_support_response("Cannot login to my account")

      expect(support_result.content).to include("Jane Smith")
      expect(support_result.content).to include("Cannot login to my account")
      expect(support_result.model).to eq("gpt-3.5-turbo")
      expect(support_result.temperature).to eq(0.3)
    end

    it "raises an error when prompt doesn't exist" do
      customer = CustomerEmail.new(customer_name: "Test User")

      expect {
        PromptEngine.render(:non_existent_prompt, {})
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "only uses active prompts" do
      # Create a different archived prompt
      archived_prompt = PromptEngine::Prompt.create!(
        name: "old-welcome-email",
        content: "Old version",
        status: "archived"
      )

      customer = CustomerEmail.new(
        customer_name: "Test User",
        product_name: "Test Product"
      )

      result = customer.generate_welcome_email

      # Should use the active version, not the archived one
      expect(result.content).not_to include("Old version")
      expect(result.content).to include("Write a welcome email")
    end

    it "handles prompts without variables" do
      simple_prompt = PromptEngine::Prompt.create!(
        name: "simple-greeting",
        content: "Hello! How can I help you today?",
        status: "active"
      )

      result = PromptEngine.render("simple-greeting", {})

      expect(result.content).to eq("Hello! How can I help you today?")
    end

    xit "preserves unmatched variables when variable is not provided" do
      customer = CustomerEmail.new(customer_name: "Alice")

      # Don't provide product_name
      result = PromptEngine.render("welcome-email",
        { customer_name: "Alice" })

      expect(result.content).to include("Alice")
      expect(result.content).to include("{{product_name}}") # Unmatched variable preserved
    end
  end

  describe "Integration with Rails callbacks" do
    before do
      # Simulate a model that uses prompts in callbacks
      class ::Article
        include ActiveModel::Model
        include ActiveModel::Callbacks

        define_model_callbacks :save

        attr_accessor :title, :content, :summary

        before_save :generate_summary

        def save
          run_callbacks :save do
            # Simulate save
            true
          end
        end

        private

        def generate_summary
          prompt_data = PromptEngine.render("article-summary",
            { title: title,
              content: content })

          # In real usage, this would call an AI service
          self.summary = "Generated summary for: #{title}"
        end
      end

      PromptEngine::Prompt.create!(
        name: "article-summary",
        content: "Summarize this article titled '{{title}}': {{content}}",
        system_message: "You are a content summarizer.",
        status: "active"
      )
    end

    after do
      Object.send(:remove_const, :Article) if defined?(::Article)
    end

    it "can be used in model callbacks" do
      article = Article.new(
        title: "Rails Best Practices",
        content: "This is a long article about Rails..."
      )

      expect { article.save }.not_to raise_error
      expect(article.summary).to eq("Generated summary for: Rails Best Practices")
    end
  end
end
