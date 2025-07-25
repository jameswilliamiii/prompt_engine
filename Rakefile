require "bundler/setup"

APP_RAKEFILE = File.expand_path("spec/dummy/Rakefile", __dir__)
load "rails/tasks/engine.rake"

load "rails/tasks/statistics.rake"

require "bundler/gem_tasks"

require "rspec/core"
require "rspec/core/rake_task"

desc "Run all specs in spec directory"
RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = "spec/**{,/*/**}/*_spec.rb"
end

# Add setup task shortcut
desc "Setup PromptEngine dummy app for development and testing"
task setup: "app:prompt_engine:setup"

task default: :spec
