require 'bundler/gem_tasks'

desc "(Re-) generate documentation and place it in the docs/ dir. Open the index.html file in there to read it."
task :docs => [:"docs:environment", :"docs:yard"]

namespace :docs do

  task :environment do
    ENV["RACK_ENV"] = "documentation"
  end

  require 'yard'

  YARD::Rake::YardocTask.new :yard do |t|
    t.files   = ['lib/**/*.rb']
    t.options = ['-odoc/'] # optional
  end

end

namespace :examples do

  desc "Run the examples."
  task :run do
    exec "bundle exec rackup examples/config.ru"
  end

end


task :default => "spec"

require 'rspec/core/rake_task'

desc "Run specs"
RSpec::Core::RakeTask.new do |t|
  t.pattern = "./spec/**/*_spec.rb"
end