require File.expand_path(File.dirname(__FILE__) + '/helpers')

describe Rack::Thumb do
  it "should render a thumbnail with width only" do
    response = request.get("/media/imagick_50x.jpg")
    response.should.be.ok
    response.content_type.should == "image/jpeg"
    dimensions(response).should == [50, 52]
  end

  it "should render a thumbnail with height only" do
    response = request.get("/media/imagick_x50.jpg")
    response.should.be.ok
    response.content_type.should == "image/jpeg"
    dimensions(response).should == [48, 50]
  end

  it "should render a thumbnail with width and height (crop-resize)" do
    response = request.get("/media/imagick_50x50.jpg")
    response.should.be.ok
    response.content_type.should == "image/jpeg"
    dimensions(response).should == [50, 50]
  end

  it "should render a thumbnail with width, height and gravity (crop-resize)" do
    response = request.get("/media/imagick_50x100-sw.jpg")
    response.should.be.ok
    response.content_type.should == "image/jpeg"
    dimensions(response).should == [50, 100]
  end

  it "should render a thumbnail with maximum width and height" do
    response = request.get("/media/imagick_50xx50.jpg")
    response.should.be.ok
    response.content_type.should == "image/jpeg"
    dimensions(response).should == [48, 50]
  end

  it "should render a thumbnail with maximum width and height from standard params, if crop option was set to false" do
    response = request(:crop => false).get("/media/imagick_50x50.jpg")
    response.should.be.ok
    response.content_type.should == "image/jpeg"
    dimensions(response).should == [48, 50]
  end

  it "should render a thumbnail with a signature" do
    sig = Digest::SHA1.hexdigest("/media/imagick_50x100-sw.jpgtest")[0..15]
    response = request(credentials).get("/media/imagick_50x100-sw-#{sig}.jpg")
    response.should.be.ok
    response.content_type.should == "image/jpeg"
    dimensions(response).should == [50, 100]
  end

  it "should not render a thumbnail that exceeds the original image's dimensions" do
    response = request.get("/media/imagick_1000x1000.jpg")
    response.should.be.ok
    response.content_type.should == "image/jpeg"
    dimensions(response).should == [572, 591]
  end

  it "should work with non-file source bodies" do
    app = lambda {[200, {"Content-Type" => "image/jpeg"}, file_content]}
    request = Rack::MockRequest.new(Rack::Thumb.new(app))
    response = request.get("/media/imagick_50x.jpg")
    response.should.be.ok
    response.content_type.should == "image/jpeg"
    dimensions(response).should == [50, 52]
  end

  it "should return bad request if the signature is invalid" do
    response = request(credentials).get("/media/imagick_50x100-sw-9922d04b14049f85.jpg")
    response.should.be.client_error
    response.body.should == "Bad thumbnail parameters in /media/imagick_50x100-sw-9922d04b14049f85.jpg\n"
  end

  it "should return bad request if the dimensions are bad" do
    response = request.get("/media/imagick_0x50.jpg")
    response.should.be.client_error
    response.body.should == "Bad thumbnail parameters in /media/imagick_0x50.jpg\n"
  end

  it "should return bad request if dimensions contain leading zeroes" do
    response = request.get("/media/imagick_50x050.jpg")
    response.should.be.client_error
    response.body.should == "Bad thumbnail parameters in /media/imagick_50x050.jpg\n"
  end

  it "should return the application's response if the source file is not found" do
    response = request.get("/media/dummy_50x50.jpg")
    response.should.be.not_found
    response.body.should == "File not found: /media/dummy.jpg\n"
  end

  it "should return the application's response if it does not recognize render options" do
    response = request(credentials).get("/media/imagick_50x50!.jpg")
    response.should.be.not_found
    response.body.should == "File not found: /media/imagick_50x50!.jpg\n"
  end

  it "should pass non-thumbnail image requests to the application" do
    response = request(credentials).get("/media/imagick.jpg")
    response.should.be.ok
    response.content_type.should == "image/jpeg"
    response.content_length.should == 97374
    response.body.bytesize.should == 97374
  end

  it "should not render on a HEAD request" do
    response = request.request("HEAD", "/media/imagick_50x50.jpg")
    response.should.be.ok
    response.content_type.should == "image/jpeg"
    response.content_length.should.be.nil
    response.body.bytesize.should == 0
  end

  it "should preserve any extra headers provided by the downstream app" do
    app = lambda {[200, {"X-Foo" => "bar", "Content-Type" => "image/jpeg"}, file_content]}
    request = Rack::MockRequest.new(Rack::Thumb.new(app))
    response = request.request("HEAD", "/media/imagick_50x50.jpg")
    response.should.be.ok
    response.content_type.should == "image/jpeg"
    response.content_length.should.be.nil
    response.headers["X-Foo"].should == "bar"
  end

  it "should forward POST/PUT/DELETE requests to the downstream app" do
    response = request.post("/media/imagick_50x50.jpg")
    response.should.not.be.successful
  end

  it "should strip file metadata by default" do
    response = request.get("/media/imagick_100xx100.jpg")
    response.body.bytesize.should == 7744
  end

  it "should not strip file metadata if option :preserve_metadata is true" do
    response = request(:preserve_metadata => true).get("/media/imagick_100xx100.jpg")
    response.body.bytesize.should == 10906
  end

  it "should accept an option to restrict files within given paths only" do
    app = Rack::Thumb.new(file_app, :urls => ["/mediafiles/"])
    expectation = /#{Regexp.escape('^(\/mediafiles\/.+)')}/
    app.instance_variable_get("@routes")[0].to_s.should =~ expectation
  end

  it "should allow regular expressions in :urls option" do
    app = Rack::Thumb.new(file_app, :urls => [/\/mediafiles\/.+\//])
    expectation = /#{Regexp.escape('^((?-mix:\/mediafiles\/.+\/).+)')}/
    app.instance_variable_get("@routes")[0].to_s.should =~ expectation
  end
end
