require 'rack'
require 'mapel'
require 'digest/sha1'
require 'tempfile'
require 'rack/thumb/version'

module Rack

#   The Rack::Thumb middleware intercepts requests for images that have urls of
#   the form <code>/path/to/image_{metadata}.ext</code> and returns rendered
#   thumbnails. Rendering options include +width+, +height+ and +gravity+. If
#   both +width+ and +height+ are supplied, images are cropped and resized
#   to fit the aspect ratio.
#
#   Rack::Thumb is file-server agnostic to provide maximum deployment
#   flexibility. Simply set it up in front of any downstream application that
#   can serve the source images. Example:
#
#     # rackup.ru
#     require 'rack/thumb'
#
#     use Rack::Thumb
#     use Rack::Static, :urls => ["/media"]
#
#     run MyApp.new
#
#   See the example directory for more <tt>Rack</tt> configurations. Because
#   thumbnailing is an expensive operation, you should run Rack::Thumb
#   behind a cache, such as <tt>Rack::Cache</tt>.
#
#   Link to thumbnails from your templates as follows:
#
#     /media/foobar_50x50.jpg     # => Crop and resize to 50x50
#     /media/foobar_50x50-nw.jpg  # => Crop and resize with northwest gravity
#     /media/foobar_50x.jpg       # => Resize to a width of 50, preserving AR
#     /media/foobar_x50.jpg       # => Resize to a height of 50, preserving AR
#
#   To prevent pesky end-users and bots from flooding your application with
#   render requests you can set up Rack::Thumb to check for a <tt>SHA-1</tt> signature
#   that is unique to every url. Using this option, only thumbnails requested
#   by your templates will be valid. Example:
#
#     use Rack::Thumb, {
#       :secret => "My secret",
#       :keylength => "16"        # => Only use 16 digits of the SHA-1 key
#     }
#
#   You can then use your +secret+ to generate secure links in your templates:
#
#     /media/foobar_50x100-sw-a267c193a7eff046.jpg  # => Successful
#     /media/foobar_120x250-a267c193a7eff046.jpg    # => Returns a bad request error
#

  class Thumb
    RE_TH_BASE = /_(\d+x|x\d+|\d+x\d+)(-(?:nw|n|ne|w|c|e|sw|s|se))?/
    RE_TH_EXT  = /(\.(?:jpg|jpeg|png|gif))?/i 
    RE_TH_RET  = /(?:@(\d+)x)?/
    TH_GRAV = {
      '-nw' => :northwest,
      '-n'  => :north,
      '-ne' => :northeast,
      '-w'  => :west,
      '-c'  => :center,
      '-e'  => :east,
      '-sw' => :southwest,
      '-s'  => :south,
      '-se' => :southeast
    }

    def initialize(app, options={})
      @app    = app
      @keylen = options[:keylength]
      @secret = options[:secret]
      @routes = generate_routes(options[:urls] || ["/"], options[:prefix])
    end

    # Generates routes given a list of prefixes.
    def generate_routes(urls, prefix = nil)
      prefix = prefix ? Regexp.escape(prefix) : ''
      urls.map do |url|
        url = url == "/" ? '' : Regexp.escape(url)
        if @keylen
          /^#{prefix}(#{url}\/.+)#{RE_TH_BASE}-([0-9a-f]{#{@keylen}})#{RE_TH_RET}#{RE_TH_EXT}$/
        else
          /^#{prefix}(#{url}\/.+)#{RE_TH_BASE}#{RE_TH_RET}#{RE_TH_EXT}$/
        end
      end
    end

    def call(env)
      dup._call(env)
    end

    def _call(env)
      response = catch(:halt) do
        throw :halt unless %w{GET HEAD}.include? env["REQUEST_METHOD"]
        @env  = env
        @path = env["PATH_INFO"]
        @routes.each do |regex|
          if match = @path.match(regex)
            @source, dim, grav, multi = extract_meta(match)
            @image = get_source_image
            @thumb = render_thumbnail(dim, grav, multi) unless head?
            serve
          end
        end
        nil
      end

      response || @app.call(env)
    end
    
    # Extracts filename and options from the path.
    def extract_meta(match)
      (@keylen ? extract_signed_meta(match) : extract_unsigned_meta(match)) or throw :halt
    end

    # Extracts filename and options from a signed path.
    def extract_signed_meta(match)
      base, dim, grav, sig, multi, ext = match.captures
      digest = Digest::SHA1.hexdigest("#{base}_#{dim}#{grav}#{ext}#{@secret}")[0..@keylen-1]
      throw(:halt, bad_request) unless sig && (sig == digest)
      [base + ext.to_s, dim, grav, multi]
    end

    # Extracts filename and options from an unsigned path.
    def extract_unsigned_meta(match)
      base, dim, grav, multi, ext = match.captures
      [base + ext.to_s, dim, grav, multi]
    end

    # Fetch the source image from the downstream app, returning the downstream
    # app's response if it is not a success.
    def get_source_image
      status, headers, body = @app.call(@env.merge("PATH_INFO" => @source))

      unless (status >= 200 && status < 300) && (headers["Content-Type"].split("/").first == "image")
        throw :halt, [status, headers, body]
      end

      @source_headers = headers

      return nil if head?
      
      if body.respond_to?(:path)
        ::File.open(body.path, 'rb')
      elsif body.respond_to?(:each)
        data = ''
        body.each { |part| data << part.to_s }
        Tempfile.new(::File.basename(@path)).tap do |f|
          f.binmode
          f.write(data)
          f.close
        end
      end
    end

    # Renders a thumbnail from the source image. Returns a Tempfile.
    def render_thumbnail(dim, grav, multi=1)
      gravity       = grav ? TH_GRAV[grav] : :center
      multiplier    = multi.to_i < 1 ? 1 : multi.to_i
      width, height = parse_dimensions(dim)
      origin_width, origin_height = Mapel.info(@image.path)[:dimensions]
      width  = [ width * multiplier, origin_width ].min if width
      height = [height * multiplier, origin_height].min if height
      output = create_tempfile
      cmd = Mapel(@image.path).strip.gravity(gravity)
      if width && height
        cmd.resize!(width, height)
      else
        cmd.resize(width, height, 0, 0, '>')
      end
      cmd.to(output.path).run
      output
    end

    # Parses the rendering options; returns false if rendering options are invalid
    def parse_dimensions(meta)
      dimensions = meta.split('x').map do |dim|
        if dim.empty?
          nil
        elsif dim[0].to_i == 0
          throw :halt, bad_request
        else
          dim.to_i
        end
      end
      dimensions.any? ? dimensions : throw(:halt, bad_request)
    end

    # Creates a new tempfile
    def create_tempfile
      Tempfile.new(::File.basename(@path)).tap { |f| f.close }
    end
    
    # Serves the thumbnail. If this is a HEAD request we strip the body as well
    # as the content length because the render was never run.
    def serve
      response = if head?
        @source_headers.delete("Content-Length")
        [200, @source_headers, []]
      else
        [200, @source_headers.merge("Content-Length" => ::File.size(@thumb.path).to_s), self]
      end

      throw :halt, response
    end

    def bad_request
      body = "Bad thumbnail parameters in #{@path}\n"
      [400, {"Content-Type" => "text/plain", "Content-Length" => body.size.to_s}, [body]]
    end

    def head?
      @env["REQUEST_METHOD"] == "HEAD"
    end

    def each
      ::File.open(@thumb.path, "rb") do |file|
        while part = file.read(8192)
          yield part
        end
      end
    end
  end
end