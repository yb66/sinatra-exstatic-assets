# encoding: UTF-8

require 'rspec'
Spec_dir = File.expand_path( File.dirname __FILE__ )


# code coverage
require 'simplecov'
SimpleCov.start do
  add_filter "/vendor/"
  add_filter "/bin/"
end

require "rack/test"
ENV['RACK_ENV'] ||= 'test'
ENV["EXPECT_WITH"] ||= "racktest"


require "logger"
logger = Logger.new STDOUT
logger.level = Logger::DEBUG
logger.datetime_format = '%a %d-%m-%Y %H%M '
LOgger = logger


Dir[ File.join( Spec_dir, "/support/**/*.rb")].each do |f| 
  logger.info "requiring #{f}"
  require f
end

require 'rack/test/accepts'
require 'timecop'

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true

  config.include Rack::Test::Accepts, :type => :request

  config.before(:each, :time_sensitive => true) do
    Timecop.freeze "2013-03-31 00:00:00 0000"
  end

  config.after(:each, :time_sensitive => true) do
    Timecop.return
  end
end

