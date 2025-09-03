require "rails_helper"

RSpec.describe "Comprehensive PromptEngine.render usage patterns", type: :integration do
  describe "All supported render patterns" do
    # Setup test prompts
    let!(:simple_active) do
      PromptEngine::Prompt.create!(
        name: "Simple Email",
        slug: "email-writer",
        content: "Write an email about this topic",
        model: "gpt-3.5-turbo",
        temperature: 0.7,
        status: "active"
      )
    end

    let!(:with_variables) do
      PromptEngine::Prompt.create!(
        name: "Customer Support",
        slug: "customer-support",
        content: "Help {{customer_name}} with {{issue}}",
        model: "gpt-4",
        temperature: 0.3,
        status: "active"
      )
    end

    let!(:versioned_prompt) do
      prompt = PromptEngine::Prompt.create!(
        name: "Onboarding Email",
        slug: "onboarding-email",
        content: "Welcome {{user_name}} to our service!",
        status: "active"
      )
      # Create a second version
      prompt.update!(content: "Hi {{user_name}}, welcome aboard!")
      # Create a third version
      prompt.update!(content: "Hello {{user_name}}, glad to have you!")
      prompt
    end

    let!(:draft_prompt) do
      PromptEngine::Prompt.create!(
        name: "New Feature",
        slug: "new-feature",
        content: "Introducing {{feature_name}} - built for you!",
        status: "draft"
      )
    end

    describe "Case 1: No variables, just option overrides" do
      it "renders with model and temperature overrides only" do
        rendered = PromptEngine.render("email-writer",
          options: { model: "gpt-4-turbo", temperature: 0.9 }
        )

        expect(rendered.content).to eq("Write an email about this topic")
        expect(rendered.model).to eq("gpt-4-turbo") # overridden
        expect(rendered.temperature).to eq(0.9) # overridden
      end

      it "works with multiple option overrides" do
        rendered = PromptEngine.render("email-writer",
          options: {
            model: "claude-3",
            temperature: 0.5,
            max_tokens: 2000
          }
        )

        expect(rendered.model).to eq("claude-3")
        expect(rendered.temperature).to eq(0.5)
        expect(rendered.max_tokens).to eq(2000)
      end
    end

    describe "Case 2: Override model settings at runtime with variables" do
      it "renders with variables and model/temperature overrides" do
        rendered = PromptEngine.render("email-writer",
          { subject: "Welcome to our platform" },
          options: { model: "gpt-4-turbo", temperature: 0.9 }
        )

        expect(rendered.content).to eq("Write an email about this topic")
        expect(rendered.model).to eq("gpt-4-turbo")
        expect(rendered.temperature).to eq(0.9)
      end

      it "properly handles variables with model overrides" do
        rendered = PromptEngine.render("customer-support",
          { customer_name: "Alice", issue: "Password reset" },
          options: { model: "gpt-4-turbo", temperature: 0.2 }
        )

        expect(rendered.content).to eq("Help Alice with Password reset")
        expect(rendered.model).to eq("gpt-4-turbo") # overridden
        expect(rendered.temperature).to eq(0.2) # overridden
      end
    end

    describe "Case 3: Load a specific version" do
      it "loads version 1 of a prompt" do
        rendered = PromptEngine.render("onboarding-email",
          { user_name: "Sarah" },
          options: { version: 1 }
        )

        expect(rendered.content).to eq("Welcome Sarah to our service!")
        expect(rendered.version_number).to eq(1)
      end

      it "loads version 2 of a prompt" do
        rendered = PromptEngine.render("onboarding-email",
          { user_name: "Bob" },
          options: { version: 2 }
        )

        expect(rendered.content).to eq("Hi Bob, welcome aboard!")
        expect(rendered.version_number).to eq(2)
      end

      it "loads specific version with model overrides" do
        rendered = PromptEngine.render("onboarding-email",
          { user_name: "Charlie" },
          options: { version: 1, model: "claude-3", temperature: 0.8 }
        )

        expect(rendered.content).to eq("Welcome Charlie to our service!")
        expect(rendered.version_number).to eq(1)
        expect(rendered.model).to eq("claude-3")
        expect(rendered.temperature).to eq(0.8)
      end
    end

    describe "Case 4: Render prompts with different statuses" do
      it "renders draft prompts when specified" do
        rendered = PromptEngine.render("new-feature",
          { feature_name: "AI Assistant" },
          options: { status: "draft" }
        )

        expect(rendered.content).to eq("Introducing AI Assistant - built for you!")
      end

      it "defaults to active status when not specified" do
        # This should fail because new-feature is draft, not active
        expect {
          PromptEngine.render("new-feature",
            { feature_name: "AI Assistant" }
          )
        }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "can explicitly request active status" do
        rendered = PromptEngine.render("customer-support",
          { customer_name: "Dave", issue: "Billing" },
          options: { status: "active" }
        )

        expect(rendered.content).to eq("Help Dave with Billing")
      end

      it "combines status with other options" do
        rendered = PromptEngine.render("new-feature",
          { feature_name: "Smart Search" },
          options: {
            status: "draft",
            model: "gpt-4",
            temperature: 0.6
          }
        )

        expect(rendered.content).to eq("Introducing Smart Search - built for you!")
        expect(rendered.model).to eq("gpt-4")
        expect(rendered.temperature).to eq(0.6)
      end
    end

    describe "Case 5: Simple render with variables only (no options)" do
      it "renders with just variables" do
        rendered = PromptEngine.render("customer-support",
          { customer_name: "John", issue: "Can't login to my account" }
        )

        expect(rendered.content).to eq("Help John with Can't login to my account")
        expect(rendered.model).to eq("gpt-4") # uses prompt's default
        expect(rendered.temperature).to eq(0.3) # uses prompt's default
      end

      it "works with multiple variables" do
        # Create a prompt with multiple variables
        multi_var = PromptEngine::Prompt.create!(
          name: "Multi Variable",
          slug: "multi-var",
          content: '{{greeting}} {{name}}, your order #{{order_id}} is {{status}}',
          status: "active"
        )

        rendered = PromptEngine.render("multi-var",
          {
            greeting: "Hello",
            name: "Alice",
            order_id: "12345",
            status: "shipped"
          }
        )

        expect(rendered.content).to eq("Hello Alice, your order #12345 is shipped")
      end
    end

    describe "Edge cases and combinations" do
      it "handles empty variables with options" do
        rendered = PromptEngine.render("email-writer", {},
          options: { temperature: 0.4 }
        )

        expect(rendered.content).to eq("Write an email about this topic")
        expect(rendered.temperature).to eq(0.4)
      end

      it "handles just slug (no variables, no options)" do
        rendered = PromptEngine.render("email-writer")

        expect(rendered.content).to eq("Write an email about this topic")
        expect(rendered.model).to eq("gpt-3.5-turbo")
        expect(rendered.temperature).to eq(0.7)
      end

      it "handles version with status and other overrides" do
        # Create an archived version
        archived = PromptEngine::Prompt.create!(
          name: "Old Template",
          slug: "old-template",
          content: "Version 1 content",
          status: "archived"
        )
        archived.update!(content: "Version 2 content")

        rendered = PromptEngine.render("old-template",
          {},
          options: {
            status: "archived",
            version: 1,
            model: "gpt-3.5",
            temperature: 0.1
          }
        )

        expect(rendered.content).to eq("Version 1 content")
        expect(rendered.model).to eq("gpt-3.5")
        expect(rendered.temperature).to eq(0.1)
      end
    end
  end
end
