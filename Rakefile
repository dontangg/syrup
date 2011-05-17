require 'bundler'
require 'rspec/core/rake_task'

Bundler::GemHelper.install_tasks

desc "Run RSpec"
RSpec::Core::RakeTask.new

task :default => :spec