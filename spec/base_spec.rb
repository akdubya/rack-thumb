require 'spec_helper'

describe Rack::Thumb do
  before do
    @app = Rack::File.new(::File.dirname(__FILE__))
    @request = Rack::MockRequest.new(Rack::Thumb.new(@app))
    @secret_request = Rack::MockRequest.new(Rack::Thumb.new(@app, :keylength => 16, :secret => "test"))
    @signature = Digest::SHA1.hexdigest("/media/imagick_50x100-sw.jpgtest")[0..15]
  end
  
  it "should render a thumbnail with width only" do
    verify_response(@request.get("/media/imagick_50x.jpg"), "image/jpeg", [50,52])
  end

  it "should render a thumbnail with height only" do
    verify_response(@request.get("/media/imagick_x50.jpg"), "image/jpeg", [48,50])
  end

  it "should render a thumbnail with width and height (crop-resize)" do
    verify_response(@request.get("/media/imagick_50x50.jpg"), "image/jpeg", [50,50])
  end

  it "should render a thumbnail with width, height and gravity (crop-resize)" do
    verify_response(@request.get("/media/imagick_50x100-sw.jpg"), "image/jpeg", [50,100])
  end

  it "should render a thumbnail with a signature" do
    verify_response(@secret_request.get("/media/imagick_50x100-sw-#{@signature}.jpg"), "image/jpeg", [50,100])
  end

  it "should not render a thumbnail that exceeds the original image's dimensions" do
    verify_response(@request.get("/media/imagick_1000x1000.jpg"), "image/jpeg", [572, 591])
  end

  it "should work with non-file source bodies" do
    app = lambda { |env| [200, {"Content-Type" => "image/jpeg"}, [::File.read(::File.dirname(__FILE__) + "/media/imagick.jpg")]] }
    request = Rack::MockRequest.new(Rack::Thumb.new(app))
    verify_response(request.get("/media/imagick_50x.jpg"), "image/jpeg", [50, 52])
  end

  it "should return bad request if the signature is invalid" do
    response = @secret_request.get("/media/imagick_50x100-sw-9922d04b14049f85.jpg")
    verify_bad_response(response, 400, "Bad thumbnail parameters in /media/imagick_50x100-sw-9922d04b14049f85.jpg\n")
  end

  it "should return bad request if the dimensions are bad" do
    response = @request.get("/media/imagick_0x50.jpg")
    verify_bad_response(response, 400, "Bad thumbnail parameters in /media/imagick_0x50.jpg\n")
  end

  it "should return bad request if dimensions contain leading zeroes" do
    response = @request.get("/media/imagick_50x050.jpg")
    verify_bad_response(response, 400, "Bad thumbnail parameters in /media/imagick_50x050.jpg\n")
  end

  it "should return the application's response if the source file is not found" do
    response = @request.get("/media/dummy_50x50.jpg")
    verify_bad_response(response, 404, "File not found: /media/dummy.jpg\n")
  end

  it "should return the application's response if it does not recognize render options" do
    response = @secret_request.get("/media/imagick_50x50!.jpg")
    verify_bad_response(response, 404, "File not found: /media/imagick_50x50!.jpg\n")
  end

  it "should pass non-thumbnail image requests to the application" do
    res = @secret_request.get("/media/imagick.jpg")
    res.status.must_equal 200
    res.content_type.must_equal "image/jpeg"
    res.content_length.must_equal 97374
    res.body.bytesize.must_equal 97374
  end

  it "should not render on a HEAD request" do
    res = @request.request("HEAD", "/media/imagick_50x50.jpg")
    res.status.must_equal 200
    res.content_type.must_equal "image/jpeg"
    res.content_length.must_be_nil
    res.body.bytesize.must_equal 0
  end

  it "should preserve any extra headers provided by the downstream app" do
    app = lambda { |env| [200, {"X-Foo" => "bar", "Content-Type" => "image/jpeg"}, ::File.open(::File.dirname(__FILE__) + "/media/imagick.jpg")] }

    request = Rack::MockRequest.new(Rack::Thumb.new(app))

    res = request.request("HEAD", "/media/imagick_50x50.jpg")
    res.status.must_equal 200
    res.content_type.must_equal "image/jpeg"
    res.content_length.must_be_nil
    res.headers["X-Foo"].must_equal "bar"
  end

  it "should forward POST/PUT/DELETE requests to the downstream app" do
    res = @request.post("/media/imagick_50x50.jpg")
    res.status.must_equal 405
  end
  
  it "should work for filenames with no extension" do
    app = lambda { |env| [200, {"Content-Type" => "image/jpeg"}, [::File.read(::File.dirname(__FILE__) + "/media/imagick.jpg")]] }
    request = Rack::MockRequest.new(Rack::Thumb.new(app))
    verify_response(request.get("/media/imagick_50x.jpg"), "image/jpeg", [50, 52])
  end
  
  it "should render a thumbnail with retina multiplier" do
    verify_response(@request.get("/media/imagick_50x50@2x.jpg"), "image/jpeg", [100, 100])
  end
  
  it "should render a thumbnail with a signature and retina multiplier" do
    verify_response(@secret_request.get("/media/imagick_50x100-sw-#{@signature}@4x.jpg"), "image/jpeg", [200, 400])
  end
end