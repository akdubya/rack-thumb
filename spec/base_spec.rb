require File.expand_path(File.dirname(__FILE__) + '/helpers')

describe Rack::Thumb do
  before do
    @app = Rack::File.new(::File.dirname(__FILE__))
  end

  it "should render a thumbnail with width only" do
    request = Rack::MockRequest.new(Rack::Thumb.new(@app))

    res = request.get("/media/imagick_50x.jpg")
    res.should.be.ok
    res.content_type.should == "image/jpeg"
    info = image_info(res.body)
    info[:dimensions].should == [50, 52]
  end

  it "should render a thumbnail with height only" do
    request = Rack::MockRequest.new(Rack::Thumb.new(@app))

    res = request.get("/media/imagick_x50.jpg")
    res.should.be.ok
    res.content_type.should == "image/jpeg"
    info = image_info(res.body)
    info[:dimensions].should == [48, 50]
  end

  it "should render a thumbnail with width and height (crop-resize)" do
    request = Rack::MockRequest.new(Rack::Thumb.new(@app))

    res = request.get("/media/imagick_50x50.jpg")
    res.should.be.ok
    res.content_type.should == "image/jpeg"
    info = image_info(res.body)
    info[:dimensions].should == [50, 50]
  end

  it "should render a thumbnail with width, height and gravity (crop-resize)" do
    request = Rack::MockRequest.new(Rack::Thumb.new(@app))

    res = request.get("/media/imagick_50x100-sw.jpg")
    res.should.be.ok
    res.content_type.should == "image/jpeg"
    info = image_info(res.body)
    info[:dimensions].should == [50, 100]
  end

  it "should render a thumbnail with maximum width and height" do
    request = Rack::MockRequest.new(Rack::Thumb.new(@app))

    res = request.get("/media/imagick_50xx50.jpg")
    res.should.be.ok
    res.content_type.should == "image/jpeg"
    info = image_info(res.body)
    info[:dimensions].should == [48, 50]
  end

  it "should render a thumbnail with maximum width and height from standard params, if crop option was set to false" do
    request = Rack::MockRequest.new(Rack::Thumb.new(@app, :crop => false))

    res = request.get("/media/imagick_50x50.jpg")
    res.should.be.ok
    res.content_type.should == "image/jpeg"
    info = image_info(res.body)
    info[:dimensions].should == [48, 50]
  end

  it "should render a thumbnail with a signature" do
    request = Rack::MockRequest.new(Rack::Thumb.new(@app, :keylength => 16,
      :secret => "test"))

    sig = Digest::SHA1.hexdigest("/media/imagick_50x100-sw.jpgtest")[0..15]
    res = request.get("/media/imagick_50x100-sw-#{sig}.jpg")
    res.should.be.ok
    res.content_type.should == "image/jpeg"
    info = image_info(res.body)
    info[:dimensions].should == [50, 100]
  end

  it "should not render a thumbnail that exceeds the original image's dimensions" do
    request = Rack::MockRequest.new(Rack::Thumb.new(@app))

    res = request.get("/media/imagick_1000x1000.jpg")
    res.should.be.ok
    res.content_type.should == "image/jpeg"
    info = image_info(res.body)
    info[:dimensions].should == [572, 591]
  end

  it "should work with non-file source bodies" do
    app = lambda { |env| [200, {"Content-Type" => "image/jpeg"},
        [::File.read(::File.dirname(__FILE__) + "/media/imagick.jpg")]] }

    request = Rack::MockRequest.new(Rack::Thumb.new(app))

    res = request.get("/media/imagick_50x.jpg")
    res.should.be.ok
    res.content_type.should == "image/jpeg"
    info = image_info(res.body)
    info[:dimensions].should == [50, 52]
  end

  it "should return bad request if the signature is invalid" do
    request = Rack::MockRequest.new(Rack::Thumb.new(@app, :keylength => 16,
      :secret => "test"))

    res = request.get("/media/imagick_50x100-sw-9922d04b14049f85.jpg")
    res.should.be.client_error
    res.body.should == "Bad thumbnail parameters in /media/imagick_50x100-sw-9922d04b14049f85.jpg\n"
  end

  it "should return bad request if the dimensions are bad" do
    request = Rack::MockRequest.new(Rack::Thumb.new(@app))

    res = request.get("/media/imagick_0x50.jpg")
    res.should.be.client_error
    res.body.should == "Bad thumbnail parameters in /media/imagick_0x50.jpg\n"
  end

  it "should return bad request if dimensions contain leading zeroes" do
    request = Rack::MockRequest.new(Rack::Thumb.new(@app))

    res = request.get("/media/imagick_50x050.jpg")
    res.should.be.client_error
    res.body.should == "Bad thumbnail parameters in /media/imagick_50x050.jpg\n"
  end

  it "should return the application's response if the source file is not found" do
    request = Rack::MockRequest.new(Rack::Thumb.new(@app))

    res = request.get("/media/dummy_50x50.jpg")
    res.should.be.not_found
    res.body.should == "File not found: /media/dummy.jpg\n"
  end

  it "should return the application's response if it does not recognize render options" do
    request = Rack::MockRequest.new(Rack::Thumb.new(@app, :keylength => 16,
      :secret => "test"))

    res = request.get("/media/imagick_50x50!.jpg")
    res.should.be.not_found
    res.body.should == "File not found: /media/imagick_50x50!.jpg\n"
  end

  it "should pass non-thumbnail image requests to the application" do
    request = Rack::MockRequest.new(Rack::Thumb.new(@app, :keylength => 16,
      :secret => "test"))

    res = request.get("/media/imagick.jpg")
    res.should.be.ok
    res.content_type.should == "image/jpeg"
    res.content_length.should == 97374
    res.body.bytesize.should == 97374
  end

  it "should not render on a HEAD request" do
    request = Rack::MockRequest.new(Rack::Thumb.new(@app))

    res = request.request("HEAD", "/media/imagick_50x50.jpg")
    res.should.be.ok
    res.content_type.should == "image/jpeg"
    res.content_length.should.be.nil
    res.body.bytesize.should == 0
  end

  it "should preserve any extra headers provided by the downstream app" do
    app = lambda { |env| [200, {"X-Foo" => "bar", "Content-Type" => "image/jpeg"},
        ::File.open(::File.dirname(__FILE__) + "/media/imagick.jpg")] }

    request = Rack::MockRequest.new(Rack::Thumb.new(app))

    res = request.request("HEAD", "/media/imagick_50x50.jpg")
    res.should.be.ok
    res.content_type.should == "image/jpeg"
    res.content_length.should.be.nil
    res.headers["X-Foo"].should == "bar"
  end

  it "should forward POST/PUT/DELETE requests to the downstream app" do
    request = Rack::MockRequest.new(Rack::Thumb.new(@app))

    res = request.post("/media/imagick_50x50.jpg")
    res.should.not.be.successful
  end
end