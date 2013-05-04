# encoding: UTF-8

require 'rubygems'
require 'bundler'
Bundler.setup(:example)

root = File.expand_path File.dirname(__FILE__)
require File.expand_path("./config.rb", File.dirname(__FILE__))


run Example.app
