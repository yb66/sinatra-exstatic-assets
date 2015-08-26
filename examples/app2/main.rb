require 'sinatra/base'
require 'sinatra/exstatic_assets'

module Example
  class App2 < Sinatra::Base
    register Sinatra::Exstatic

    configure do
      set :root, __dir__
      set :public_folder, Proc.new { File.join(root, "public") }
    end

    get "/" do
      erb :index
    end
  end
end