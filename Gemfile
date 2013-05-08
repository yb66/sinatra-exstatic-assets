source "http://rubygems.org"

# Specify your gem's dependencies in sinatra-static-assets.gemspec
gemspec

group :example do
  gem "sinatra"
end

group :test do
  gem "rspec"
  gem "rack-test"
  gem "simplecov"
  gem 'turn', :require => false
  gem "timecop"
  gem "rack-test-accepts", :require => "rack/test/accepts"
end

group :development do
  gem "rake"
  gem "wirble"
  gem "reek"
  gem 'webrick', '~> 1.3.1' # get rid of stupid warnings.
end

group :documentation do
  gem "yard"
  gem "maruku"
end