require 'spec_helper'

module PromptEngine  
  RSpec.describe "InstallGenerator files" do
    let(:engine_root) { File.expand_path("../../../../../..", __FILE__) }
    
    describe "generator structure" do
      it "has the generator file" do
        generator_file = File.join(engine_root, "lib/generators/prompt_engine/install/install_generator.rb")
        expect(File.exist?(generator_file)).to be true
      end
      
      it "has the initializer template" do
        template_file = File.join(engine_root, "lib/generators/prompt_engine/install/templates/initializer.rb")
        expect(File.exist?(template_file)).to be true
      end
      
      it "generator contains expected methods" do
        generator_file = File.join(engine_root, "lib/generators/prompt_engine/install/install_generator.rb")
        content = File.read(generator_file)
        
        expect(content).to include("class InstallGenerator")
        expect(content).to include("def install_migrations")
        expect(content).to include("def add_route_mount")
        expect(content).to include("def create_initializer")
        expect(content).to include("def add_javascript_registration")
        expect(content).to include("def add_stylesheet")
      end
      
      it "initializer template contains configuration" do
        template_file = File.join(engine_root, "lib/generators/prompt_engine/install/templates/initializer.rb")
        content = File.read(template_file)
        
        expect(content).to include("PromptEngine.configure")
        expect(content).to include("max_prompt_length")
        expect(content).to include("supported_providers")
      end
    end
    
    describe "JavaScript entry point" do
      it "has the JavaScript index file" do
        js_file = File.join(engine_root, "app/javascript/prompt_engine/index.js")
        expect(File.exist?(js_file)).to be true
      end
      
      it "exports registerControllers function" do
        js_file = File.join(engine_root, "app/javascript/prompt_engine/index.js")
        content = File.read(js_file)
        
        expect(content).to include("export function registerControllers")
        expect(content).to include("registerControllers(application)")
      end
    end
    
    describe "engine configuration" do
      it "includes JavaScript asset paths" do
        engine_file = File.join(engine_root, "lib/prompt_engine/engine.rb")
        content = File.read(engine_file)
        
        expect(content).to include('root.join("app/javascript")')
        expect(content).to include("prompt_engine.asset_paths")
      end
    end
  end
end