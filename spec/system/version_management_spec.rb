require 'rails_helper'

RSpec.describe "Version management", type: :system do
  before do
    driven_by(:rack_test)
  end

  let!(:prompt) { create(:prompt, name: "Test Prompt", content: "Version 1 content") }
  let!(:version_1) { prompt.versions.first }
  let!(:version_2) { prompt.update!(content: "Version 2 content"); prompt.versions.first }
  let!(:version_3) { prompt.update!(content: "Version 3 content"); prompt.versions.first }

  describe "Viewing version history from prompt page" do
    it "navigates to version history from prompt show page" do
      visit "/active_prompt/prompts/#{prompt.id}"

      click_link "Version History"

      expect(page).to have_current_path("/active_prompt/prompts/#{prompt.id}/versions")
      expect(page).to have_content("Version History")
      expect(page).to have_content(prompt.name)
    end
  end

  describe "Version history page" do
    before { visit "/active_prompt/prompts/#{prompt.id}/versions" }

    it "displays all versions in descending order" do
      versions = page.all('.version-item')
      expect(versions.count).to eq(3)

      # Check order - newest first
      within(versions[0]) do
        expect(page).to have_content("Version 3")
        expect(page).to have_content("Updated: content")
        expect(page).to have_css(".badge--primary", text: "Current")
      end

      within(versions[1]) do
        expect(page).to have_content("Version 2")
        expect(page).to have_content("Updated: content")
      end

      within(versions[2]) do
        expect(page).to have_content("Version 1")
        expect(page).to have_content("Initial version")
      end
    end

    it "shows timeline visualization with markers" do
      expect(page).to have_css(".versions-timeline")
      expect(page).to have_css(".version-item__marker-dot", count: 3)
      expect(page).to have_css(".version-item__marker-line", count: 2)
    end

    it "displays version metadata" do
      within(".version-item", text: "Version 2") do
        expect(page).to have_content("Created")
        expect(page).to have_content("Model")
        expect(page).to have_content("Temperature")
        expect(page).to have_content("Max Tokens")
      end
    end

    it "shows content preview for each version" do
      within(".version-item", text: "Version 2") do
        expect(page).to have_content("Content Preview:")
        expect(page).to have_content("Version 2 content")
      end
    end

    it "provides action buttons for non-current versions" do
      # Current version should not have Compare/Restore buttons
      within(".version-item--current") do
        expect(page).to have_link("View")
        expect(page).not_to have_link("Compare")
        expect(page).not_to have_button("Restore")
      end

      # Previous versions should have all buttons
      within(".version-item", text: "Version 2") do
        expect(page).to have_link("View")
        expect(page).to have_link("Compare")
        expect(page).to have_button("Restore")
      end
    end

    it "navigates back to prompt" do
      click_link "Back to Prompt"
      expect(page).to have_current_path("/active_prompt/prompts/#{prompt.id}")
    end
  end

  describe "Viewing single version" do
    it "displays version details" do
      visit "/active_prompt/prompts/#{prompt.id}/versions"

      within(".version-item", text: "Version 2") do
        click_link "View"
      end

      expect(page).to have_current_path("/active_prompt/prompts/#{prompt.id}/versions/#{version_2.id}")
      expect(page).to have_content("Version 2")
      expect(page).to have_content(prompt.name)
    end

    it "shows complete version information" do
      visit "/active_prompt/prompts/#{prompt.id}/versions/#{version_2.id}"

      # Version info
      expect(page).to have_content("Version Information")
      expect(page).to have_content("Version Number")
      expect(page).to have_content("2")
      expect(page).to have_content("Change Description")
      expect(page).to have_content("Updated: content")

      # Prompt content
      expect(page).to have_content("Prompt Content")
      expect(page).to have_content("Version 2 content")

      # System message
      expect(page).to have_content("System Message")

      # Model settings
      expect(page).to have_content("Model Settings")
      expect(page).to have_content("Temperature")
      expect(page).to have_content("0.7")
    end

    it "provides restore button for non-current versions" do
      visit "/active_prompt/prompts/#{prompt.id}/versions/#{version_2.id}"

      expect(page).to have_button("Restore This Version")
    end

    it "does not show restore button for current version" do
      visit "/active_prompt/prompts/#{prompt.id}/versions/#{version_3.id}"

      expect(page).not_to have_button("Restore This Version")
    end

    it "navigates back to version history" do
      visit "/active_prompt/prompts/#{prompt.id}/versions/#{version_2.id}"

      click_link "Back to History"
      expect(page).to have_current_path("/active_prompt/prompts/#{prompt.id}/versions")
    end
  end

  describe "Comparing versions" do
    it "compares version with previous version" do
      visit "/active_prompt/prompts/#{prompt.id}/versions"

      within(".version-item", text: "Version 2") do
        click_link "Compare"
      end

      expect(page).to have_current_path("/active_prompt/prompts/#{prompt.id}/versions/#{version_2.id}/compare")
      expect(page).to have_content("Compare Versions")
      expect(page).to have_content("Version 1 → Version 2")
    end

    it "displays changed fields with diff visualization" do
      visit "/active_prompt/prompts/#{prompt.id}/versions/#{version_2.id}/compare"

      # Content should be shown as changed
      within(".version-compare__section", text: "Content") do
        expect(page).to have_content("Old Value")
        expect(page).to have_content("Version 1 content")
        expect(page).to have_content("New Value")
        expect(page).to have_content("Version 2 content")
      end
    end

    it "shows change summaries for both versions" do
      visit "/active_prompt/prompts/#{prompt.id}/versions/#{version_2.id}/compare"

      expect(page).to have_content("Change Description")
      expect(page).to have_content(version_1.change_description)
      expect(page).to have_content(version_2.change_description)
    end

    it "only displays fields that changed" do
      # Create versions with only content changed
      version_2.update_columns(
        model: version_1.model,
        temperature: version_1.temperature,
        max_tokens: version_1.max_tokens
      )

      visit "/active_prompt/prompts/#{prompt.id}/versions/#{version_2.id}/compare"

      # Should only show content section
      expect(page).to have_css(".version-compare__section", text: "Content")
      expect(page).not_to have_css(".version-compare__section", text: "Model")
      expect(page).not_to have_css(".version-compare__section", text: "Temperature")
    end
  end

  describe "Restoring a version" do
    it "restores prompt to selected version" do
      original_content = prompt.content

      visit "/active_prompt/prompts/#{prompt.id}/versions"

      within(".version-item", text: "Version 2") do
        click_button "Restore"
      end

      expect(page).to have_content("Prompt restored to version 2")
      expect(page).to have_current_path("/active_prompt/prompts/#{prompt.id}")

      # Verify content was restored
      expect(page).to have_content("Version 2 content")
    end

    it "shows success flash message after restore" do
      visit "/active_prompt/prompts/#{prompt.id}/versions"

      within(".version-item", text: "Version 2") do
        click_button "Restore"
      end

      expect(page).to have_css(".admin-notification--notice", text: "Prompt restored to version 2")
    end

    it "can restore from version detail page" do
      visit "/active_prompt/prompts/#{prompt.id}/versions/#{version_1.id}"

      click_button "Restore This Version"

      expect(page).to have_content("Prompt restored to version 1")
      expect(page).to have_current_path("/active_prompt/prompts/#{prompt.id}")
    end
  end

  describe "Empty state" do
    # Note: This test would need a prompt without automatic version creation
    # Since prompts automatically create an initial version, we'll skip this test
    # or would need to modify the Prompt model to allow skipping version creation
  end

  describe "Error handling" do
    # Note: System tests don't raise exceptions - they render error pages
    # These tests would need to be in controller specs instead
  end

  describe "UI elements and styling" do
    before { visit "/active_prompt/prompts/#{prompt.id}/versions" }

    it "displays timeline with proper CSS classes" do
      expect(page).to have_css(".versions-timeline")
      expect(page).to have_css(".version-item")
      expect(page).to have_css(".version-item--current")
      expect(page).to have_css(".version-item__marker")
      expect(page).to have_css(".version-card")
    end

    it "uses proper button styling" do
      expect(page).to have_css(".button--secondary")
      expect(page).to have_css(".button--small")
    end

    it "displays badges correctly" do
      expect(page).to have_css(".badge--primary", text: "Current")
    end
  end

  describe "Turbo confirmations" do
    it "includes turbo confirm data attribute on restore buttons" do
      visit "/active_prompt/prompts/#{prompt.id}/versions"

      restore_button = find(".version-item", text: "Version 2").find("button", text: "Restore")
      expect(restore_button['data-turbo-confirm']).to eq("Are you sure you want to restore this version?")
    end
  end
end
