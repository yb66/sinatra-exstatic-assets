require_relative "../exstatic_assets.rb"

module Sinatra
  module Exstatic
    # Extends the Asset class, for using types of format
    # other than mtime_int
    # Just require this file and then use the format of your choice.
    # @example
    #
    #   require 'sinatra/exstatic_assets/formats'
    #
    #   configure do
    #     # Set all timestamps to use SHA1 of the file.
    #     app.set :timestamp_format, :sha1
    #   end
    #
    #   # or just call it on an individual basis:
    #   stylesheet_tag "css/main.css", timestamp_format: :sha1
    module Formats

      def sha1
        Digest::SHA1.file(fullpath).hexdigest
      end
    
    end

    class Asset
      include Formats
    end
  end
end