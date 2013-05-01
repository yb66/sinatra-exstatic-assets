require 'sinatra/base'

module Sinatra
  module StaticAssets
    module Helpers

      @@asset_timestamps_cache = {}
      @@asset_mutex ||= Mutex.new

      # In HTML <link> and <img> tags have no end tag.
      # In XHTML, on the contrary, these tags must be properly closed.
      #
      # We can choose the appropriate behaviour with +closed+ option:
      #
      #   image_tag "/images/foo.png", :alt => "Foo itself", :closed => true
      #
      # The default value of +closed+ option is +false+.
      #
      def image_tag(source, options = {})
        options[:src] = url_for source
        tag "img", options
      end

      def stylesheet_link_tag(*sources)
        list, options = extract_options sources
        list.map {|source|
          stylesheet_tag source, options
        }.join "\n"
      end

      def javascript_script_tag(*sources)
        list, options = extract_options sources
        list.map {|source|
          javascript_tag source, options
        }.join "\n"
      end

      alias :javascript_include_tag :javascript_script_tag

      def link_to(desc, url, options = {})
        tag("a", options.merge(:href => url_for(url))) {
          desc
        }
      end
      
      def link_favicon_tag(source = nil, options = {})
        source = "favicon.ico" if source.nil? or source.empty?

        # xhtml style like <link rel="shortcut icon" href="http://example.com/myicon.ico" />
        options[:rel] ||= "shortcut icon" if settings.xhtml

        # html5 style like <link rel="icon" href="http://example.com/myicon.ico" />
        options[:rel] ||= "icon"

        options[:href] = url_for(source)
        
        tag "link", options
      end

      private

      def url_for(addr, absolute = false)
        uri(addr, absolute == :full ? true : false, true)
      end


      # TODO change this
      def is_uri?(path)
        path =~ %r{\A
                  [\-a-z]+
                  ://         # wtf?
                    |
                  ^cid:       # wtf?
                    |
                  ^//         # again, wtf?
                \Z}x
      end

      def asset_url_for(source)
        url = url_for(source)
        return url if is_uri?(source)
          
        timestamp = asset_timestamp(source)
        url += "?#{timestamp}" if timestamp
        return url
      end

      def asset_timestamp(source)
        timestamp = if @@asset_timestamps_cache.has_key? source
          @@asset_timestamps_cache[source]
        else
          path = asset_file_path(source)
          timestamp = File.exists?(path) && File.mtime(path).to_i.to_s
          @@asset_mutex.synchronize {
            @@asset_timestamps_cache[source] = timestamp
          }
          timestamp
        end
      end


      def asset_file_path(path)
        File.join(settings.public_folder, path)
      end

      def tag(name, local_options = {})
        start_tag = "<#{name} #{tag_options(local_options)}".strip
        if block_given?
          "#{start_tag}>#{yield}</#{name}>"
        else
          settings.xhtml ? 
            "#{start_tag}/>" :
            "#{start_tag}>"
        end
      end

      def tag_options(options)
        options.sort
               .map {|key, value| %(#{key}="#{value}") }
               .join " "
      end

      def stylesheet_tag(source, options = {})
        tag "link", 
            { :type => "text/css",
              :charset => "utf-8",
              :media => "screen",
              :rel => "stylesheet",
              :href => asset_url_for(source)
            }.merge(options)
      end

      def javascript_tag(source, options = {})
        tag("script", 
            { :type => "text/javascript", 
              :charset => "utf-8",
              :src => asset_url_for(source)
            }.merge(options)) {} # empty tag
      end

      def extract_options(a)
        opts = a.last.respond_to?(:keys) ? a.pop : {}
        [a, opts]
      end

    end

    def self.registered(app)
      app.helpers StaticAssets::Helpers
      app.disable :xhtml
    end
  end

  register StaticAssets
end
