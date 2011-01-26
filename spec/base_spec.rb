require File.expand_path(File.dirname(__FILE__) + '/helpers')

describe Rack::Thumb do

  def mock_request(options = {})
    Rack::MockRequest.new(Rack::Builder.new do
      use Rack::Thumb, options
      run Rack::File.new(::File.dirname(__FILE__))
    end)
  end

  def image_dimensions(response)
    image_info(response.body)[:dimensions]
  end


  it "should render a thumbnail with width only" do
    response = mock_request.get("/media/imagick_50x.jpg")

    response.should.be.ok
    response.content_type.should == "image/jpeg"
    image_dimensions(response).should == [50, 52]
  end

  it "should render a thumbnail with height only" do
    response = mock_request.get("/media/imagick_x50.jpg")

    response.should.be.ok
    response.content_type.should == "image/jpeg"
    image_dimensions(response).should == [48, 50]
  end

  it "should render a thumbnail with width and height (crop-resize)" do
    response = mock_request.get("/media/imagick_50x50.jpg")

    response.should.be.ok
    response.content_type.should == "image/jpeg"
    image_dimensions(response).should == [50, 50]
  end

  it "should render a thumbnail with width, height and gravity (crop-resize)" do
    response = mock_request.get("/media/imagick_50x100-sw.jpg")

    response.should.be.ok
    response.content_type.should == "image/jpeg"
    image_dimensions(response).should == [50, 100]
  end

  it "should not render a thumbnail that exceeds the original image's dimensions" do
    response = mock_request.get("/media/imagick_1000x1000.jpg")

    response.should.be.ok
    response.content_type.should == "image/jpeg"
    image_dimensions(response).should == [572, 591]
  end

  it "should render a thumbnail with a signature" do
    signature = Digest::SHA1.hexdigest("/media/imagick_50x100-sw.jpgtest")[0..15]
    response  = mock_request(:keylength => 16, :secret => 'test').
                  get("/media/imagick_50x100-sw-#{ signature }.jpg")

    response.should.be.ok
    response.content_type.should == "image/jpeg"
    image_dimensions(response).should == [50, 100]
  end

  it "should pass non-thumbnail image requests to the application" do
    response = mock_request.get("/media/imagick.jpg")

    response.should.be.ok
    response.content_type.should == "image/jpeg"
    response.content_length.should == 97374
    response.body.bytesize.should == 97374
  end

  it "should not render on a HEAD request" do
    response = mock_request.request("HEAD", "/media/imagick_50x50.jpg")

    response.should.be.ok
    response.content_type.should == "image/jpeg"
    response.content_length.should.be.nil
    response.body.bytesize.should == 0
  end

  it "should preserve any extra headers provided by the downstream app" do
    app = lambda do |env|
      [ 200,
        { "X-Foo" => "bar", "Content-Type" => "image/jpeg" },
        ::File.open(::File.dirname(__FILE__) + "/media/imagick.jpg") ]
    end

    response = Rack::MockRequest.new(app).request("HEAD",
                                                  "/media/imagick_50x50.jpg")

    response.should.be.ok
    response.content_type.should == "image/jpeg"
    response.content_length.should.be.nil
    response.headers["X-Foo"].should == "bar"
  end

  it "should forward POST requests to the downstream app" do
    response = mock_request.post("/media/imagick_50x50.jpg")

    response.should.not.be.successful
  end

  it "should forward PUT requests to the downstream app" do
    response = mock_request.put("/media/imagick_50x50.jpg")

    response.should.not.be.successful
  end

  it "should forward DELETE requests to the downstream app" do
    response = mock_request.delete("/media/imagick_50x50.jpg")

    response.should.not.be.successful
  end

  it "should work with non-file source bodies" do
    app = Rack::Builder.new do
      use Rack::Thumb

      run(lambda do |env|
            [ 200,
              { "Content-Type" => "image/jpeg" },
              ::File.open(::File.dirname(__FILE__) + "/media/imagick.jpg") ]
          end)
    end

    response = Rack::MockRequest.new(app).get("/media/imagick_50x.jpg")

    response.should.be.ok
    response.content_type.should == "image/jpeg"
    image_dimensions(response).should == [50, 52]
  end

  it "should return bad request with width of 0" do
    response = mock_request.get("/media/imagick_0x50.jpg")

    response.should.be.client_error
    response.body.should == "Bad thumbnail parameters in /media/imagick_0x50.jpg\n"
  end

  it "should return bad request with height of 0" do
    response = mock_request.get("/media/imagick_50x0.jpg")

    response.should.be.client_error
    response.body.should == "Bad thumbnail parameters in /media/imagick_50x0.jpg\n"
  end

  it "should return bad request when height has leading zero" do
    response = mock_request.get("/media/imagick_50x050.jpg")

    response.should.be.client_error
    response.body.should == "Bad thumbnail parameters in /media/imagick_50x050.jpg\n"
  end

  it "should return bad request when width has leading zero" do
    response = mock_request.get("/media/imagick_050x50.jpg")

    response.should.be.client_error
    response.body.should == "Bad thumbnail parameters in /media/imagick_050x50.jpg\n"
  end

  it "should return bad request if the signature is invalid" do
    response = mock_request(:keylength => 16, :secret => 'test').
                 get("/media/imagick_50x100-sw-9922d04b14049f85.jpg")

    response.should.be.client_error
    response.body.should == "Bad thumbnail parameters in /media/imagick_50x100-sw-9922d04b14049f85.jpg\n"
  end

  it "should return the application's response if the source file is not found" do
    response = mock_request.get("/media/dummy_50x50.jpg")

    response.should.be.not_found
    response.body.should == "File not found: /media/dummy.jpg\n"
  end

  it "should return the application's response if it does not recognize render options" do
    response = mock_request.get("/media/imagick_50x50!.jpg")

    response.should.be.not_found
    response.body.should == "File not found: /media/imagick_50x50!.jpg\n"
  end

  it "should render a thumbnail when mounted as a mapped app" do
    app = Rack::Builder.new do
            map '/thumb/nail' do
              use Rack::Thumb
              run Rack::File.new(::File.dirname(__FILE__))
            end
          end

    response = Rack::MockRequest.new(app).get("/thumb/nail/media/imagick_50x.jpg")

    response.should.be.ok
    response.content_type.should == "image/jpeg"
    image_dimensions(response).should == [50, 52]
  end

end
