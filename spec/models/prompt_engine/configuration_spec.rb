require "rails_helper"

module PromptEngine
  RSpec.describe Configuration do
    describe "#back_path" do
      it "defaults to nil" do
        expect(described_class.new.back_path).to be_nil
      end
    end

    describe "#back_label" do
      it "defaults to '← Back'" do
        expect(described_class.new.back_label).to eq("← Back")
      end
    end

    describe "PromptEngine.configure" do
      it "allows setting back_path" do
        PromptEngine.configure { |c| c.back_path = "/dashboard" }
        expect(PromptEngine.config.back_path).to eq("/dashboard")
      ensure
        PromptEngine.config.back_path = nil
      end

      it "allows setting back_label" do
        PromptEngine.configure { |c| c.back_label = "← Back to Dashboard" }
        expect(PromptEngine.config.back_label).to eq("← Back to Dashboard")
      ensure
        PromptEngine.config.back_label = "← Back"
      end
    end
  end
end
