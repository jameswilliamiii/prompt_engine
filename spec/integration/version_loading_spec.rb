require "rails_helper"

RSpec.describe "Version loading behavior" do
  describe "PromptEngine.render with versions" do
    let!(:prompt) do
      # Create initial prompt
      p = PromptEngine::Prompt.create!(
        name: "Versioned Prompt",
        slug: "versioned",
        content: "Version 1: Hello {{name}}",
        model: "gpt-3.5-turbo",
        temperature: 0.5,
        status: "active"
      )
      
      # Create version 2
      p.update!(content: "Version 2: Hi {{name}}")
      
      # Create version 3 and change status to draft
      p.update!(
        content: "Version 3: Hey {{name}}",
        status: "draft"
      )
      
      p
    end

    describe "default version loading" do
      it "loads the most current version when no version specified and status matches" do
        result = PromptEngine.render("versioned", 
          { name: "Alice" },
          options: { status: "draft" }
        )
        expect(result.content).to eq("Version 3: Hey Alice")
        expect(result.version).to eq(3)
      end

      it "respects status filter when no version specified" do
        # The prompt is now draft, so this should fail with default active status
        expect {
          PromptEngine.render("versioned", { name: "Bob" })
        }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "loads current version when status matches" do
        result = PromptEngine.render("versioned", 
          { name: "Charlie" },
          options: { status: "draft" }
        )
        expect(result.content).to eq("Version 3: Hey Charlie")
        expect(result.version).to eq(3)
        expect(result.status).to eq("draft")
      end
    end

    describe "specific version loading" do
      it "loads version 1 regardless of current prompt status" do
        result = PromptEngine.render("versioned",
          { name: "Dave" },
          options: { version: 1 }
        )
        expect(result.content).to eq("Version 1: Hello Dave")
        expect(result.version).to eq(1)
      end

      it "loads version 2 regardless of current prompt status" do
        result = PromptEngine.render("versioned",
          { name: "Eve" },
          options: { version: 2 }
        )
        expect(result.content).to eq("Version 2: Hi Eve")
        expect(result.version).to eq(2)
      end

      it "ignores status filter when version is specified" do
        # Even though we're asking for 'active' status, it should still load version 2
        # because when version is specified, status filter is ignored
        result = PromptEngine.render("versioned",
          { name: "Frank" },
          options: { version: 2, status: "active" }
        )
        expect(result.content).to eq("Version 2: Hi Frank")
        expect(result.version).to eq(2)
        expect(result.status).to eq("active") # The requested status is preserved in options
      end

      it "uses default active status when loading specific version without status override" do
        # Load version 1, even though the prompt's current status is 'draft'
        result = PromptEngine.render("versioned",
          { name: "Grace" },
          options: { version: 1 }
        )
        # When no status is specified in options, it uses the default 'active' status
        expect(result.status).to eq("active") # Default status from PromptEngine.render
      end
    end

    describe "version with model overrides" do
      it "applies model overrides to specific versions" do
        result = PromptEngine.render("versioned",
          { name: "Henry" },
          options: { version: 1, model: "gpt-4", temperature: 0.8 }
        )
        expect(result.content).to eq("Version 1: Hello Henry")
        expect(result.version).to eq(1)
        expect(result.model).to eq("gpt-4")
        expect(result.temperature).to eq(0.8)
      end
    end

    describe "error handling" do
      it "raises error when version doesn't exist" do
        expect {
          PromptEngine.render("versioned",
            { name: "Ivan" },
            options: { version: 99 }
          )
        }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "raises error when prompt doesn't exist" do
        expect {
          PromptEngine.render("non-existent",
            { name: "Jane" },
            options: { version: 1 }
          )
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    describe "archived prompt with versions" do
      let!(:archived_prompt) do
        p = PromptEngine::Prompt.create!(
          name: "Archived Prompt",
          slug: "archived-one",
          content: "V1: Archived {{text}}",
          status: "active"
        )
        
        # Create v2
        p.update!(content: "V2: Updated {{text}}")
        
        # Archive it
        p.update!(status: "archived")
        
        p
      end

      it "cannot load archived prompt without specifying status" do
        expect {
          PromptEngine.render("archived-one", { text: "content" })
        }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "can load specific version of archived prompt" do
        result = PromptEngine.render("archived-one",
          { text: "content" },
          options: { version: 1 }
        )
        expect(result.content).to eq("V1: Archived content")
        expect(result.version).to eq(1)
      end

      it "can load current version with archived status" do
        result = PromptEngine.render("archived-one",
          { text: "content" },
          options: { status: "archived" }
        )
        expect(result.content).to eq("V2: Updated content")
        expect(result.version).to eq(2)
        expect(result.status).to eq("archived")
      end
    end
  end

  describe "RenderedPrompt accessors" do
    let!(:test_prompt) do
      PromptEngine::Prompt.create!(
        name: "Test Accessors",
        slug: "test-accessors",
        content: "Test {{name}}",
        status: "active"
      )
    end

    it "provides access to all options through individual methods" do
      result = PromptEngine.render("test-accessors",
        { name: "Kate" },
        options: { 
          model: "claude-3",
          temperature: 0.3,
          max_tokens: 2000
        }
      )

      expect(result.version).to eq(1) # First version
      expect(result.status).to eq("active") # Default active status
      expect(result.model).to eq("claude-3")
      expect(result.temperature).to eq(0.3)
      expect(result.max_tokens).to eq(2000)
      expect(result.options).to eq({
        model: "claude-3",
        temperature: 0.3,
        max_tokens: 2000,
        status: "active"  # Default status is included in options
      })
    end
  end
end