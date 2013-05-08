# -*- encoding: utf-8 -*-

$:.push File.expand_path("../lib", __FILE__)
require "sinatra/static_assets/version"

Gem::Specification.new do |s|
  s.name        = "sinatra-static-assets"
  s.version     = Sinatra::StaticAssets::VERSION
  s.authors     = ["Włodek Bzyl", "Iain Barnett"]
  s.email       = ["iainspeed@gmail.com"]
  s.homepage    = "https://github.com/yb66/sinatra-static-assets"
  s.summary     = %q{A Sinatra extension of helpers for static assets}
  s.description = %q{Helpers for writing the HTML and caching of static assets}

  s.add_dependency 'sinatra'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths = ["lib"]
end
