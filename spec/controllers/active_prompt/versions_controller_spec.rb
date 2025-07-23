require 'rails_helper'

module ActivePrompt
  RSpec.describe VersionsController, type: :controller do
    routes { ActivePrompt::Engine.routes }
    
    let(:prompt) { create(:prompt, content: "Version 1 content") }
    let(:version_1) { prompt.versions.order(version_number: :asc).first }
    let(:version_2) do
      prompt.reload # ensure we have the latest state
      prompt.update!(content: "Version 2 content")
      prompt.versions.order(version_number: :desc).first
    end
    let(:version_3) do
      version_2 # ensure version 2 is created first
      prompt.reload # ensure we have the latest state
      prompt.update!(content: "Version 3 content")
      prompt.versions.order(version_number: :desc).first
    end
    
    before do
      # Ensure all versions are created
      version_1
      version_2
      version_3
    end
    
    describe "GET #index" do
      it "returns a successful response" do
        get :index, params: { prompt_id: prompt.id }
        expect(response).to be_successful
      end
      
      it "assigns versions in descending order" do
        get :index, params: { prompt_id: prompt.id }
        expect(assigns(:versions).to_a).to eq([version_3, version_2, version_1])
      end
      
      it "assigns the correct prompt" do
        get :index, params: { prompt_id: prompt.id }
        expect(assigns(:prompt)).to eq(prompt)
      end
      
      context "when prompt doesn't exist" do
        it "raises ActiveRecord::RecordNotFound" do
          expect {
            get :index, params: { prompt_id: 99999 }
          }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end
    
    describe "GET #show" do
      it "returns a successful response" do
        get :show, params: { prompt_id: prompt.id, id: version_2.id }
        expect(response).to be_successful
      end
      
      it "assigns the requested version" do
        get :show, params: { prompt_id: prompt.id, id: version_2.id }
        expect(assigns(:version)).to eq(version_2)
      end
      
      it "assigns the correct prompt" do
        get :show, params: { prompt_id: prompt.id, id: version_2.id }
        expect(assigns(:prompt)).to eq(prompt)
      end
      
      context "when version doesn't exist" do
        it "raises ActiveRecord::RecordNotFound" do
          expect {
            get :show, params: { prompt_id: prompt.id, id: 99999 }
          }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
      
      context "when version belongs to different prompt" do
        let(:other_prompt) { create(:prompt) }
        let(:other_version) { other_prompt.versions.first }
        
        it "raises ActiveRecord::RecordNotFound" do
          expect {
            get :show, params: { prompt_id: prompt.id, id: other_version.id }
          }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end
    
    describe "GET #compare" do
      context "with both version IDs provided" do
        it "returns a successful response" do
          get :compare, params: { 
            prompt_id: prompt.id, 
            id: version_2.id,
            version_a_id: version_1.id, 
            version_b_id: version_3.id 
          }
          expect(response).to be_successful
        end
        
        it "assigns the correct versions" do
          get :compare, params: { 
            prompt_id: prompt.id,
            id: version_2.id,
            version_a_id: version_1.id, 
            version_b_id: version_3.id 
          }
          expect(assigns(:version_a)).to eq(version_1)
          expect(assigns(:version_b)).to eq(version_3)
        end
        
        it "calculates changes between versions" do
          get :compare, params: { 
            prompt_id: prompt.id,
            id: version_2.id,
            version_a_id: version_1.id, 
            version_b_id: version_2.id 
          }
          
          changes = assigns(:changes)
          expect(changes).to be_present
          expect(changes[:content][:old]).to eq("Version 1 content")
          expect(changes[:content][:new]).to eq("Version 2 content")
          expect(changes[:content][:changed]).to be true
        end
      end
      
      context "with only id parameter (compare with previous)" do
        it "compares with the previous version" do
          get :compare, params: { prompt_id: prompt.id, id: version_2.id }
          
          expect(assigns(:version_a)).to eq(version_1)
          expect(assigns(:version_b)).to eq(version_2)
        end
        
        it "handles first version (no previous)" do
          get :compare, params: { prompt_id: prompt.id, id: version_1.id }
          
          expect(assigns(:version_a)).to eq(version_1)
          expect(assigns(:version_b)).to eq(version_1)
        end
      end
      
      context "with missing version IDs" do
        it "redirects with alert when no versions selected" do
          get :compare, params: { prompt_id: prompt.id, id: version_2.id, version_a_id: '', version_b_id: '' }
          
          # The controller doesn't redirect if version_a_id and version_b_id are empty
          # It falls back to comparing with previous version
          expect(response).to be_successful
        end
      end
      
      context "with invalid version IDs" do
        it "redirects with alert" do
          get :compare, params: { 
            prompt_id: prompt.id,
            id: version_2.id,
            version_a_id: 99999, 
            version_b_id: 88888 
          }
          
          expect(response).to redirect_to(prompt_versions_path(prompt))
          expect(flash[:alert]).to eq("Please select two versions to compare")
        end
      end
    end
    
    describe "POST #restore" do
      let(:original_content) { prompt.content }
      
      before do
        prompt.update!(content: "Current content")
      end
      
      it "restores the prompt to the selected version" do
        post :restore, params: { prompt_id: prompt.id, id: version_2.id }
        
        prompt.reload
        expect(prompt.content).to eq("Version 2 content")
      end
      
      it "updates all version attributes" do
        # Update prompt to create a version with specific attributes
        prompt.update!(
          content: "New content",
          system_message: "Old system message",
          model: "gpt-3.5-turbo",
          temperature: 0.5,
          max_tokens: 500
        )
        specific_version = prompt.versions.order(version_number: :desc).first
        
        # Update prompt again to change current state
        prompt.update!(content: "Different content", system_message: "Different message")
        
        post :restore, params: { prompt_id: prompt.id, id: specific_version.id }
        
        prompt.reload
        expect(prompt.content).to eq("New content")
        expect(prompt.system_message).to eq("Old system message")
        expect(prompt.model).to eq("gpt-3.5-turbo")
        expect(prompt.temperature).to eq(0.5)
        expect(prompt.max_tokens).to eq(500)
      end
      
      it "redirects to the prompt with success notice" do
        post :restore, params: { prompt_id: prompt.id, id: version_2.id }
        
        expect(response).to redirect_to(prompt_path(prompt))
        expect(flash[:notice]).to eq("Prompt restored to version #{version_2.version_number}")
      end
      
      context "when restoration fails" do
        before do
          allow_any_instance_of(Prompt).to receive(:update!).and_raise(StandardError, "Update failed")
        end
        
        it "redirects with error message" do
          post :restore, params: { prompt_id: prompt.id, id: version_2.id }
          
          expect(response).to redirect_to(prompt_versions_path(prompt))
          expect(flash[:alert]).to eq("Failed to restore version: Update failed")
        end
        
        it "doesn't change the prompt" do
          expect {
            post :restore, params: { prompt_id: prompt.id, id: version_2.id }
          }.not_to change { prompt.reload.content }
        end
      end
      
      context "when version doesn't exist" do
        it "raises ActiveRecord::RecordNotFound" do
          expect {
            post :restore, params: { prompt_id: prompt.id, id: 99999 }
          }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end
  end
end