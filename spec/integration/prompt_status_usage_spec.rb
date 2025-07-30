require "rails_helper"

RSpec.describe "Using prompts with status filtering in Rails" do
  describe "Real-world usage scenarios" do
    before do
      # Create prompts in different statuses for the same feature
      create(:prompt,
        name: "Welcome Email - Active",
        slug: "welcome-email",
        content: "Welcome {{user_name}}! Your account is now active.",
        status: "active"
      )

      create(:prompt,
        name: "Welcome Email - Draft V2", 
        slug: "welcome-email-v2",
        content: "Hi {{user_name}}! Welcome aboard! 🎉",
        status: "draft"
      )

      create(:prompt,
        name: "Welcome Email - Old",
        slug: "welcome-email-old",
        content: "Dear {{user_name}}, Welcome to our service.",
        status: "archived"
      )
    end

    context "in production environment" do
      it "uses only active prompts by default" do
        # Simulating a mailer or service object
        result = PromptEngine.render("welcome-email", { user_name: "Alice" })
        expect(result.content).to eq("Welcome Alice! Your account is now active.")
      end
    end

    context "in preview/staging environment" do
      it "can test draft prompts before making them active" do
        # Testing a new version before deployment
        result = PromptEngine.render("welcome-email-v2", 
          { user_name: "Bob" },
          { status: "draft" }
        )
        expect(result.content).to eq("Hi Bob! Welcome aboard! 🎉")
      end
    end

    context "for historical reference" do
      it "can access archived prompts when needed" do
        # Viewing old version for comparison or audit
        result = PromptEngine.render("welcome-email-old",
          { user_name: "Charlie" },
          { status: "archived" }
        )
        expect(result.content).to eq("Dear Charlie, Welcome to our service.")
      end
    end

    context "admin interface usage" do
      it "allows previewing any status in the playground" do
        # Admin can test prompts in any status
        draft_result = PromptEngine.render("welcome-email-v2",
          { user_name: "Admin" },
          { status: "draft" }
        )
        expect(draft_result.content).to include("Admin")

        # Same admin can also test the active version
        active_result = PromptEngine.render("welcome-email",
          { user_name: "Admin" },
          { status: "active" }
        )
        expect(active_result.content).to include("Admin")
      end
    end
  end

  describe "Migration path for existing code" do
    let!(:prompt) { create(:prompt, slug: "notification", content: "Alert: {{message}}", status: "active") }

    it "existing code continues to work without changes" do
      # Old code that doesn't know about status parameter
      result = PromptEngine.render("notification", { message: "System update" })
      expect(result.content).to eq("Alert: System update")
    end

    it "new code can explicitly specify status" do
      # New code that wants to be explicit
      result = PromptEngine.render("notification", 
        { message: "System update" },
        { status: "active" }
      )
      expect(result.content).to eq("Alert: System update")
    end
  end

  describe "Error handling" do
    it "provides clear error when prompt not found with status" do
      expect {
        PromptEngine.render("non-existent", {}, { status: "active" })
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "provides clear error when prompt exists but not in requested status" do
      create(:prompt, slug: "test", content: "Test", status: "draft")
      
      expect {
        PromptEngine.render("test", {}, { status: "active" })
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "Complex rendering scenarios" do
    let!(:prompt) do
      create(:prompt,
        slug: "complex-prompt",
        content: "Hello {{name}}, the answer is {{answer}}",
        system_message: "You are a helpful assistant",
        model: "gpt-4",
        temperature: 0.7,
        status: "draft"
      )
    end

    it "handles status along with all other rendering options" do
      result = PromptEngine.render("complex-prompt",
        { name: "User", answer: "42" },
        { status: "draft", model: "gpt-4-turbo", temperature: 0.5 }
      )

      expect(result.content).to eq("Hello User, the answer is 42")
      expect(result.system_message).to eq("You are a helpful assistant")
      expect(result.model).to eq("gpt-4-turbo") # overridden
      expect(result.temperature).to eq(0.5) # overridden
    end

    it "handles status with version rendering" do
      # Update prompt to create a new version
      prompt.update!(content: "Version 2: Hi {{name}}, result is {{answer}}")

      # Render the first version with status
      result = PromptEngine.render("complex-prompt",
        { name: "Alice", answer: "correct" },
        { status: "draft", version: 1 }
      )

      expect(result.content).to eq("Hello Alice, the answer is correct")
    end
  end
end