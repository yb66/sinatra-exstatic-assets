require 'sinatra/base'
require 'digest/sha1'

# @see https://sinatrarb.com/intro The framework
module Sinatra

  # A Sinatra extension for helping with static assets. You probably want to start with {Helpers}.
  module Exstatic

    # For creating HTML tags.
    class Tag < ::String

      # @param [String] name The tag name e.g. `link`.
      # @param [Hash] options With the exception of any options listed here, these are passed to the tag to make the HTML attributes.
      # @option options [TrueClass] :closed Whether to self-close the link XHTML style or not.
      # @param [#call] block The contents of the block are wrapped by the HTML tag e.g. <p>This is from the block</p>
      # @example
      #   Tag.new "img", {src: "/images/foo.jpg", width: "500"}
      #   # => "<img src="/images/foo.jpg" width="500" />"
      def initialize( name, options={}, &block )
        @name       = name
        @closed = (c = options.delete(:closed)).nil? ? true : c
        @options    = options
        @attributes = self.class.make_attributes @options
        @block      = block
        super tag
      end

      attr_reader :attributes, :options, :name

      private

 
      # @yield Its return value is used as the contents of the HTML tag.
      def tag
        return @tag if @tag
        start_tag = "<#{@name} #{@attributes}".strip
        @tag = if @block
          "#{start_tag}>#{@block.call}</#{name}>"
        elsif @closed
          "#{start_tag} />"
        else
          "#{start_tag}>"
        end
      end


      # Takes a hash and transforms it into a string of HTML attributes.
      # @param [Hash] options
      # @return [String]
      def self.make_attributes( options )
        options.sort
               .map {|key, value| %(#{key}="#{value}") }
               .join " "
      end

    end


    # Encapsulates an asset, be it a stylesheet, an image…
    class Asset < String

      attr_reader :fullpath

      # @param [String] filename Either the file name (and path relative to the public folder) or the external HTTP link.
      # @param [String] asset_dir The asset directory. When used with Sinatra this will default to the directory defined by the `public_folder` setting.
      def initialize( filename, asset_dir=nil, timestamp_format=nil ) # TODO failure strategy
        if asset_dir.nil?
          # TODO should this strip the leading slash?
          filename, asset_dir = [File.basename(filename), File.dirname(filename)]
        end
        # TODO fail if asset_dir.nil?
        super filename
        @timestamp_format = timestamp_format
        @fullpath = File.join( asset_dir, filename ) unless is_uri?
      end


      # If the asset is a local file this gets the timestamp.
      # @return [Integer]
      def timestamp
        @timestamp ||= !is_uri? && exists? && send(@timestamp_format)
      end

      # Takes the timestamp and returns it as a querystring.
      # @return [String] `?ts=TIMESTAMP`
      def querystring
        timestamp ? "?ts=#{timestamp}" : nil
      end

      # We only need to check for a scheme/protocol to know
      # it's not a file.
      URI_PATTERN = %r{\A
                    (?:
                      [A-z]+
                      \:
                    )?        # The protocol part. It's optional.
                    // /?     # There will always be at least 2 //
                  }x

      # Tests whether the asset is a file or an HTTP link by checking the scheme portion.
      # @note
      #   A url will match:
      #   http://example.com
      #   //example.com
      #   but www.example.com or example.com will be treated as a file.
      # @return [TrueClass]
      def is_uri?
        self =~ URI_PATTERN ? true : false
      end


      # Convenience, mainly for my convenience in stubbing during tests.
      # @return [TrueClass]
      def exists?
        File.exists? fullpath
      end


      # Convenience, mainly for my convenience in stubbing during tests.
      # @return [Int]
      def mtime_int
        File.mtime( fullpath ).to_i
      end
    end


    # The private instance methods.
    # @api private
    module Private

      private

      # Wraps around Sinatra::Helpers#uri. Appends a querystring if passed an Asset object.
      # @param [String,#querystring] addr
      # @param [Hash] options
      # @option options [TrueClass] :absolute see Sinatra::Helpers#uri
      # @option options [TrueClass] :script_name Whether to prepend the SCRIPT_NAME env variable.
      # @return [String]
      # @see Sinatra::Helpers#uri
      def sss_url_for(addr, options, url_opts)
        absolute = url_opts.delete :absolute
        absolute = false if absolute.nil?
        scr = url_opts.delete(:script_name)
        script_name =
          if addr.is_uri?
            false
          elsif addr.start_with?("/")
            scr.nil? ?
              true :
              scr
          else
            false
          end
        href = uri addr, absolute, script_name

        timestamp =
          if scr == false
            false
          else
            #   timestamp |
            #       nil       t
            #       f     |   f
            #       t     |   t
            if options[:timestamp] && options[:timestamp] == false
              false
            else
              true
            end
          end
        opts = {timestamp: timestamp}.merge options

        addr.respond_to?(:querystring) && opts[:timestamp] ?
          "#{href}#{addr.querystring}" :
          href
      end


      # The default options passed with a stylesheet asset.
      DEFAULT_CSS = {
#               :type     => "text/css", # not needed with HTML5
        :charset  => "utf-8",
        :media    => "screen",
        :rel      => "stylesheet"
      }


      # Produce a stylesheet link tag.
      # @param [String] source The file or HTML resource.
      # @param [Hash] options
      # @option options [String] :asset_dir The directory the asset is held. Defaults to Sinatra's `public_folder` setting.
      # @option options [Hash] :url_options Options for devising the URL.
      # @option options [TrueClass] :script_name Whether to prepend the SCRIPT_NAME env variable.
      # @return [Tag]
      def sss_stylesheet_tag(source, options, url_opts)
        asset = Asset.new source, options.delete(:asset_dir), options.delete(:timestamp_format)
        href = sss_url_for asset, options, url_opts
        Tag.new "link", DEFAULT_CSS.merge(:href => href)
                                   .merge(options)
      end


      # Default options for the javascript script tags.
      DEFAULT_JS = {
#         :type => "text/javascript", 
        :charset => "utf-8",
      }


      # Produce a javascript script tag.
      # @see #sss_stylesheet_tag but there is no `closed` option here.
      def sss_javascript_tag(source, options, url_opts)
        asset = Asset.new source, options.delete(:asset_dir), options.delete(:timestamp_format)
        href = sss_url_for asset, options, url_opts
        Tag.new("script", DEFAULT_JS.merge(:src => href)
                                            .merge(options)          
        ) {}
      end


      # Make's sure the options don't get mixed up with the other args.
      def sss_extract_options(a)
        opts = a.last.respond_to?(:keys) ?
          a.pop || {} :
          {}

        url_opts = opts.empty? ?
          {} :
          {
            absolute: opts.delete(:absolute),
            script_name: opts.delete(:script_name),
          }.reject{|k,v| v.nil? }
        a = [nil] if a == []
        [a, opts, url_opts]
      end


      # @see #sss_stylesheet_tag
      def sss_image_tag(source, options, url_opts)
        options[:src] = sss_url_for Asset.new( source, options.delete(:asset_dir), options.delete(:timestamp_format) ), options, url_opts
        Tag.new "img", options
      end


      # @param [String] source
      # @param [Hash] options
      # @option options [TrueClass] :script_name whether to append the script_name environment variable or not
      # @example
      #   favicon_tag
      #   # => <link href="/favicon.ico" rel="icon">
      def sss_favicon_tag(source, options, url_opts)
        source = "/favicon.ico" if source.nil? or source.empty?

        # xhtml style like <link rel="shortcut icon" href="http://example.com/myicon.ico" />
        options[:rel] ||= settings.xhtml ? "shortcut icon" : "icon"
        asset = Asset.new source, options.delete(:asset_dir), options.delete(:timestamp_format)
        options[:href] = sss_url_for asset, options.merge(timestamp: false), url_opts
        Tag.new "link", options
      end

    end

    # These are the helpers available to a Sinatra app using the extension.
    # @example
    #   # For a classic app
    #   require 'sinatra/exstatic'
    #   # That's all for a classic app, the helpers
    #   # are now available.
    #
    #   # For a modular app
    #   require 'sinatra/base'
    #   require 'sinatra/exstatic'
    #   class MyApp < Sinatra::Base
    #     helpers Sinatra::Exstatic
    module Helpers
      include Private

      # @!method image_tag(*sources)
      #   Produce an HTML img tag.
      #   @param [String] sources The file or HTML resource.
      #   @param [Hash] options
      #   @option options [String] :asset_dir The directory the asset is held. Defaults to Sinatra's `public_folder` setting.
      #   @option options [Hash] :url_options Options for devising the URL. (see sss_url_for)
      #   @return [#to_s]
      #   @example
      #     image_tag "/images/big-fish.jpg", width: "500", height: "250", alt: "The biggest fish in the world!"
      #     # => <img alt="The biggest fish in the world!" height="250" src="/images/big-fish.jpg?ts=1367933468" width="500" />

      # @!method stylesheet_tag(*sources)
      #   Produce an HTML link tag to a stylesheet.
      #   @param [String] sources The file or HTML resource.
      #   @param [Hash] options
      #   @option options [String] :asset_dir The directory the asset is held. Defaults to Sinatra's `public_folder` setting.
      #   @option options [Hash] :url_options Options for devising the URL. (see sss_url_for)
      #   @return [#to_s]
      #   @example
      #     stylesheet_tag "/css/screen.css"
      #     # => <link charset="utf-8" href="/css/screen.css?ts=1367678587" media="screen" rel="stylesheet">

      # @!method javascript_tag(*sources)
      #   Produce an HTML script tag.
      #   @param [String] sources The file or HTML resource.
      #   @param [Hash] options
      #   @option options [String] :asset_dir The directory the asset is held. Defaults to Sinatra's `public_folder` setting.
      #   @option options [Hash] :url_options Options for devising the URL. (see sss_url_for)
      #   @return [#to_s]
      #   @example
      #     javascript_tag "http://code.jquery.com/jquery-1.9.1.min.js"
      #     # => <script charset="utf-8" src="http://code.jquery.com/jquery-1.9.1.min.js"></script>
      %w{image_tag stylesheet_tag javascript_tag favicon_tag}.each do |method_name|
        define_method method_name do |*args|
          list, options, url_opts = sss_extract_options args
          list.map {|source|
            asset_dir = options.delete(:asset_dir) ||
                        settings.static_assets_dir ||
                        settings.public_folder
            timestamp_format = options.delete(:timestamp_format) ||
                                settings.timestamp_format ||
                                :mtime_int # default
            send "sss_#{method_name}", source, options.merge({asset_dir: asset_dir, timestamp_format: timestamp_format}), url_opts
          }.join "\n"
        end
      end

      
      alias_method :img_tag, :image_tag
      alias_method :css_tag, :stylesheet_tag
      alias_method :stylesheet, :stylesheet_tag
      alias_method :javascript_include_tag, :javascript_tag
      alias_method :js_tag, :javascript_tag
      alias_method :script_tag, :javascript_tag

      alias_method :link_favicon_tag, :favicon_tag
      alias_method :favicon, :favicon_tag

    end

    # Extending
    # @see {Sinatra::Exstatic::Formats} to extend timestamp_format
    def self.registered(app)
      app.helpers Exstatic::Helpers
      app.disable :xhtml
      app.set :static_assets_dir, nil
      app.set :timestamp_format, :mtime_int
    end
  end

  register Exstatic
end
