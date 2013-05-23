require 'sinatra/base'
require 'sinatra/exstatic_assets'

module Example
  class App2 < Sinatra::Base
    register Sinatra::Exstatic

    get "/" do
      erb :index
    end
  end
end