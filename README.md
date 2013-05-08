## Sinatra Static Assets ##

This is a fork/reworking of [wbzyl](https://github.com/wbzyl/sinatra-static-assets)'s library. I had many of the same requirements that the original library catered for, but some different ones too, and the beauty of open source code is you get to scratch your own itch! Many thanks to the contributors to that library for all their hard work and sharing the code.

### What does it do? ###

It's a Sinatra extension that has some handy helpers for dealing with static assets, like stylesheets and images, in your views.

### What's different from the other library? ###

* There's no `link_to` method (it doesn't handle assets so it was cut).
* There was a mutex in the library to handle timestamps and race conditions around that. That's gone.
* The helpers now look at the timestamp for the file they're linking to, and add that as a querystring parameter to the link displayed in the view. This will help client browsers cache the file (add something like Rack Cache to aid with this).
* There are some new options to give more control over whether the script_tag environment variable is prepended.
* More aliases, and shorter aliases.
* The tests are now a mixture of integration and unit test, but written using RSpec. There's also test coverage via SimpleCov, which is close to 100%.
* More API docs via Yardoc.

### Installation ###

Via Rubygems:

    gem install "sinatra-static-assets"

Via Bundler, put this in your Gemfile:

    gem "sinatra-static-assets", :require => "sinatra/static-assets"

### Usage ###

Here's a quick example, but there are more in the `examples` directory:

    require 'sinatra'
    require 'haml' # the lib doesn't rely on Haml, it's engine agnostic:)
    require 'sinatra/static-assets'
    
    get "/" do
      haml :index
    end
    
    @@ layout
    !!!
    %title Example
    = favicon
    = css_tag "/css/screen.css"
    = js_tag "/js/helpers.js"
    = js_tag "http://code.jquery.com/jquery-1.9.1.min.js" 
    %body
      = yield
    
    @@ index
    %dt
      %dd This is an interesting photo
      %dl
        %a{ href: "http://www.flickr.com/photos/redfernneil/1317915651/" }
          = img "http://www.flickr.com/photos/redfernneil/1317915651/" width: 500, height: 250, alt: "Something about the photo"

There is also more detailed documentation on each helper in the {Sinatra::Static::Helpers} API docs.

### TODO ###

* Make it easy to pass in caching options.
* Default dirs set up for things like /css, /images etc.
* An image link tag.
* Caching of the timestamps (but I'm not sure it's needed or worth it).

### Licence ###

See the LICENCE file.