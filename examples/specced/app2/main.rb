require 'sinatra/base'
require 'sinatra/static_assets'

module Example
  class App2 < Sinatra::Base
    register Sinatra::StaticAssets

    get "/" do
      erb :index
    end
  end
end