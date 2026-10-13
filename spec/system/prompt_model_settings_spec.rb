require "rails_helper"

RSpec.describe "Model settings on the prompt form", type: :system, js: true do
  let(:prompt) { create(:prompt, model: "claude-opus-5-5", effort: "high") }

  it "shows effort and hides temperature for a model that takes effort" do
    visit "/prompt_engine/prompts/#{prompt.id}/edit"

    expect(page).to have_select("Effort", selected: "High")
    expect(page).to have_no_field("Temperature")
  end

  it "swaps the fields when the model changes" do
    visit "/prompt_engine/prompts/#{prompt.id}/edit"

    select "GPT-4.1", from: "AI Model"

    expect(page).to have_field("Temperature")
    expect(page).to have_no_select("Effort")
  end

  it "clears the temperature when switching to a model that rejects it" do
    gpt_prompt = create(:prompt, model: "gpt-4.1", temperature: 0.7)
    visit "/prompt_engine/prompts/#{gpt_prompt.id}/edit"

    select "Claude Opus 5.5", from: "AI Model"
    click_button "Update Prompt"

    expect(page).to have_content("Prompt was successfully updated.")
    expect(gpt_prompt.reload.temperature).to be_nil
  end

  it "keeps a stored temperature hidden on load when the model is unchanged" do
    prompt.update_columns(temperature: 0.7)
    visit "/prompt_engine/prompts/#{prompt.id}/edit"

    click_button "Update Prompt"

    expect(page).to have_content("Prompt was successfully updated.")
    expect(prompt.reload.temperature).to eq(0.7)
  end

  it "saves the chosen effort" do
    visit "/prompt_engine/prompts/#{prompt.id}/edit"

    select "Low", from: "Effort"
    click_button "Update Prompt"

    expect(page).to have_content("Prompt was successfully updated.")
    expect(prompt.reload.effort).to eq("low")
  end
end
