require 'sinatra/base'
require 'sinatra/static_assets'

module Example
  class App < Sinatra::Base
    register Sinatra::StaticAssets

    get "/" do
      erb :index
    end
  
  end
end