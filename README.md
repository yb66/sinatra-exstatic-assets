## Sinatra Exstatic Assets ##

### Master branch build status ###

Master branch:
[![Build Status](https://travis-ci.org/yb66/sinatra-exstatic-assets.png?branch=master)](https://travis-ci.org/yb66/sinatra-exstatic-assets)

Develop branch:
[![Build Status](https://travis-ci.org/yb66/sinatra-exstatic-assets.png?branch=develop)](https://travis-ci.org/yb66/sinatra-exstatic-assets)

### Preamble ###

This is a fork/reworking of [wbzyl](https://github.com/wbzyl/sinatra-static-assets)'s library. I had many of the same requirements that the original library catered for, but some different ones too, and the beauty of open source code is you get to scratch your own itch! Many thanks to the contributors to that library for all their hard work and sharing the code.

### What does it do? ###

It's a Sinatra extension that has some handy helpers for dealing with static assets, like stylesheets and images, in your views.

### What's different from the other library? ###

* There's no `link_to` method (it doesn't handle assets so it was cut).
* There was a mutex in the library to handle timestamps and race conditions around that. That's gone.
* The helpers now look at the timestamp for the file they're linking to, and add that as a querystring parameter to the link displayed in the view. This will help client browsers cache the file (add something like Rack Cache to aid with this).
* There are some new options to give more control over whether the `script_tag` environment variable is prepended.
* More aliases, and shorter aliases.
* The tests are now a mixture of integration and unit test, but written using RSpec. There's also test coverage via SimpleCov, which is close to 100%.
* More API docs via Yardoc.

### Version numbers ###

This library uses [semver](http://semver.org/) to version the **library**. That means the library version is ***not*** an indicator of quality but a way to manage changes.

### Installation ###

#### via Rubygems ####

    gem install sinatra-exstatic-assets

and in your code:

    require 'sinatra/exstatic_assets'

#### via Bundler ####

Put this in your Gemfile:

    gem "sinatra-exstatic-assets", :require => "sinatra/exstatic_assets"

### Usage ###

Here's a quick example, but there are more in the `examples` directory:


      require 'sinatra'
      require 'haml' # the lib doesn't rely on Haml, it's engine agnostic:)
      require 'sinatra/exstatic_assets'

      enable :inline_templates # the interesting bit below
      
      get "/" do
        haml :index
      end
      
      __END__
      
      @@layout
      
      !!!
      %title Example
      = favicon
      = css_tag "/css/screen.css"
      = js_tag "/js/helpers.js"
      = js_tag "http://code.jquery.com/jquery-1.9.1.min.js"
      %body
        = yield
      
      @@index
      
      %dt
        %dd This is an interesting photo
        %dl
          %a{ href: "http://www.flickr.com/photos/redfernneil/1317915651/" }
            = img "http://www.flickr.com/photos/redfernneil/1317915651/", width: 500, height: 250, alt: "Something about the photo"


There is also more detailed documentation on each helper in the {Sinatra::Exstatic::Helpers} API docs.

## Formats ##

The time format is the result of the file's `mtime`. If you wish for a different kind of format, SHA1 of the file is available (and I may add more). To use:

      require 'sinatra/exstatic_assets/formats'
      register Sinatra::Exstatic

      configure do
        set :timestamp_format, :sha1
      end

And now the value returned will be the SHA1 hash of the file. You can override the choice by passing the `timestamp_format` to the method:

      = css_tag "/css/screen.css", timestamp_format: :mtime


### TODO ###

* Make it easy to pass in caching options.
* Default dirs set up for things like /css, /images etc.
* An image link tag.
* Caching of the timestamps (but I'm not sure it's needed or worth it).  

### Licence ###

See the LICENCE file.