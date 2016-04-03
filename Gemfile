source "https://rubygems.org"

# Specify your gem's dependencies in sinatra-static-assets.gemspec
gemspec

group :example do
  gem "sinatra"
end

group :test do
  gem "rspec"
  gem "rspec-its"
  gem "mocha"
  gem "rack-test"
  gem "simplecov"
  gem 'turn', :require => false
  gem "rack-test-accepts", :require => "rack/test/accepts"
  gem "timecop"
end

group :development do
  gem 'json', '~> 1.8.3'
  gem "rake"
  unless RUBY_ENGINE == 'jruby' || RUBY_ENGINE == "rbx"
    gem "pry-byebug"
    gem "pry-doc"
  end
  gem 'webrick', '~> 1.3.1' # get rid of stupid warnings.
end

group :documentation do
  gem "yard"
  gem "maruku"
end