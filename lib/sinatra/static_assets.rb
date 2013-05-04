require 'sinatra/base'

module Sinatra
  module StaticAssets

    class Tag < ::String
      DEFAULT_OPTIONS = {}

      def initialize( name, options={}, &block )
        @name       = name
        @closed = (c = options.delete(:closed)).nil? ? true : c
        @options    = DEFAULT_OPTIONS.merge options
        @attributes = self.class.make_attributes @options
        @block      = block
        super tag
      end

      attr_reader :attributes, :options, :name

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

      def self.make_attributes( options )
        options.sort
               .map {|key, value| %(#{key}="#{value}") }
               .join " "
      end

    end


    class Asset < ::String

      attr_reader :fullpath

      def initialize( filename, asset_dir=nil ) # TODO failure strategy
        if asset_dir.nil?
          filename, asset_dir = [File.basename(filename), File.dirname(filename)]
        end
        # TODO fail if asset_dir.nil?
        super filename
        @fullpath = File.join( asset_dir, filename ) unless is_uri?
      end

      def timestamp
        @timestamp ||= !is_uri? && File.exists?(fullpath) && File.mtime(fullpath).to_i
      end

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

      # @note
      #   A url will match:
      #   http://example.com
      #   //example.com
      #   but www.example.com or example.com will be treated as a file.
      def is_uri?
        self =~ URI_PATTERN ? true : false
      end
    end

    module Private

      def sss_url_for(addr, options=nil)
        options ||= {}
        absolute = options.fetch :absolute, false
        script_tag = options.fetch :script_tag, true
        href = uri addr, absolute, script_tag
        addr.respond_to?(:querystring) ?
          "#{href}#{addr.querystring}" :
          href
      end

      DEFAULT_CSS = {
#               :type     => "text/css", # not needed with HTML5
        :charset  => "utf-8",
        :media    => "screen",
        :rel      => "stylesheet"
      }

      def sss_stylesheet_tag(source, options = {})
        asset_dir = options.delete(:asset_dir) || settings.public_folder
        asset = Asset.new source, asset_dir
        href = sss_url_for( asset )
        Tag.new "link", DEFAULT_CSS.merge(:href => href)
                                   .merge(options)
            
      end

      DEFAULT_JS = {
#         :type => "text/javascript", 
        :charset => "utf-8"
      }

      def sss_javascript_tag(source, options = {})
        asset = Asset.new source, settings.public_folder
        href = sss_url_for asset 
        Tag.new("script", DEFAULT_JS.merge(:src => href)
                                            .merge(options)          
        ) {}
      end

      def sss_extract_options(a)
        opts = a.last.respond_to?(:keys) ? a.pop : {}
        [a, opts]
      end

      # In HTML <link> and <img> tags have no end tag.
      # In XHTML, on the contrary, these tags must be properly closed.
      #
      # We can choose the appropriate behaviour with +closed+ option:
      #
      #   image_tag "/images/foo.png", :alt => "Foo itself", :closed => true
      #
      # The default value of +closed+ option is +false+.
      #
      def sss_image_tag(source, options = {})
        options[:src] = sss_url_for Asset.new( source, settings.public_folder )
        Tag.new "img", options
      end

    end


    module Helpers
      include Private


      %w{image_tag stylesheet_tag javascript_tag}.each do |method_name|
        define_method method_name do |*sources|
          list, options = sss_extract_options sources
          list.map {|source|
            send "sss_#{method_name}", source, options
          }.join "\n"
        end
      end

      alias_method :img_tag, :image_tag
      alias_method :css_tag, :stylesheet_tag
      alias_method :stylesheet, :stylesheet_tag
      alias_method :javascript_include_tag, :javascript_tag
      alias_method :js_tag, :javascript_tag
      alias_method :script_tag, :javascript_tag
      
      def favicon_tag(*args)
        source, options = sss_extract_options args
        source = "favicon.ico" if source.nil? or source.empty?

        # xhtml style like <link rel="shortcut icon" href="http://example.com/myicon.ico" />
        options[:rel] ||= settings.xhtml ? "shortcut icon" : "icon"

        options[:href] = sss_url_for(source, options.delete(:url_options))
        
        Tag.new "link", options
      end

      alias_method :link_favicon_tag, :favicon_tag

    end

    def self.registered(app)
      app.helpers StaticAssets::Helpers
      app.disable :xhtml
    end
  end

  register StaticAssets
end
