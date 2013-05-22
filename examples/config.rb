require File.expand_path "./app/main.rb", File.dirname(__FILE__)
require File.expand_path "./app2/main.rb", File.dirname(__FILE__)

module Example
  def self.app
    app = Rack::Builder.app do 
      map "/app2" do
        run Example::App2
      end
      
      map "/" do
        run Example::App
      end
    end
    #run app
  end
end