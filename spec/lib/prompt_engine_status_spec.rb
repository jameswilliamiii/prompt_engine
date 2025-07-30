require "rails_helper"

RSpec.describe PromptEngine do
  describe "status scoping when rendering prompts" do
    let!(:active_prompt) do
      create(:prompt, 
        name: "Active Greeting",
        slug: "greeting",
        content: "Hello {{name}}!",
        status: "active"
      )
    end

    let!(:draft_prompt) do
      create(:prompt,
        name: "Draft Greeting",
        slug: "draft-greeting", 
        content: "Draft: Hello {{name}}!",
        status: "draft"
      )
    end

    let!(:archived_prompt) do
      create(:prompt,
        name: "Archived Greeting",
        slug: "archived-greeting",
        content: "Archived: Hello {{name}}!",
        status: "archived"
      )
    end

    # Create a prompt with same slug but different status to test scoping
    let!(:draft_greeting_same_slug) do
      # Since slug must be unique, we'll test with different approach
      create(:prompt,
        name: "Draft Version of Greeting",
        slug: "greeting-draft",
        content: "Draft Version: Hello {{name}}!",
        status: "draft"
      )
    end

    describe ".render" do
      context "without status parameter" do
        it "defaults to finding active prompts" do
          result = PromptEngine.render("greeting", { name: "World" })
          expect(result.content).to eq("Hello World!")
        end

        it "raises error if no active prompt exists with the slug" do
          expect {
            PromptEngine.render("draft-greeting", { name: "World" })
          }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context "with status parameter" do
        it "finds draft prompts when status is specified" do
          result = PromptEngine.render("draft-greeting", { name: "World" }, { status: "draft" })
          expect(result.content).to eq("Draft: Hello World!")
        end

        it "finds archived prompts when status is specified" do
          result = PromptEngine.render("archived-greeting", { name: "World" }, { status: "archived" })
          expect(result.content).to eq("Archived: Hello World!")
        end

        it "finds active prompts when status is explicitly specified" do
          result = PromptEngine.render("greeting", { name: "World" }, { status: "active" })
          expect(result.content).to eq("Hello World!")
        end

        it "raises error if prompt with specified status doesn't exist" do
          expect {
            PromptEngine.render("greeting", { name: "World" }, { status: "archived" })
          }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context "with nil status" do
        it "finds any prompt regardless of status when status is nil" do
          # This tests the ability to bypass status filtering
          result = PromptEngine.find("greeting", status: nil)
          expect(result).to eq(active_prompt)
        end
      end

      context "with other rendering options" do
        it "correctly passes through variables along with status" do
          result = PromptEngine.render("draft-greeting", 
            { name: "Alice" },
            { status: "draft", model: "gpt-4", temperature: 0.7 }
          )
          expect(result.content).to eq("Draft: Hello Alice!")
          expect(result.model).to eq("gpt-4")
          expect(result.temperature).to eq(0.7)
        end

        it "handles version parameter along with status" do
          # Create a second version of the draft prompt
          draft_prompt.update!(content: "Draft V2: Hey {{name}}!")
          
          result = PromptEngine.render("draft-greeting",
            { name: "Bob" },
            { status: "draft", version: 1 }
          )
          expect(result.content).to eq("Draft: Hello Bob!")
        end
      end
    end

    describe ".find" do
      it "defaults to active status" do
        prompt = PromptEngine.find("greeting")
        expect(prompt).to eq(active_prompt)
        expect(prompt.status).to eq("active")
      end

      it "finds prompts with specified status" do
        prompt = PromptEngine.find("draft-greeting", status: "draft")
        expect(prompt).to eq(draft_prompt)
        expect(prompt.status).to eq("draft")
      end

      it "finds any status when status is nil" do
        prompt = PromptEngine.find("archived-greeting", status: nil)
        expect(prompt).to eq(archived_prompt)
      end
    end

    describe ".[]" do
      it "always defaults to active status" do
        prompt = PromptEngine["greeting"]
        expect(prompt).to eq(active_prompt)
        expect(prompt.status).to eq("active")
      end

      it "raises error for non-active prompts" do
        expect {
          PromptEngine["draft-greeting"]
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "backwards compatibility" do
    let!(:prompt) { create(:prompt, slug: "test-prompt", content: "Test {{var}}", status: "active") }

    it "maintains existing behavior when no status is provided" do
      # Old usage should still work
      result = PromptEngine.render("test-prompt", { var: "value" })
      expect(result.content).to eq("Test value")
    end

    it "maintains existing behavior for find method" do
      found = PromptEngine.find("test-prompt")
      expect(found).to eq(prompt)
    end
  end
end