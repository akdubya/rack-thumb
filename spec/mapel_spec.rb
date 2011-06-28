require File.expand_path(File.dirname(__FILE__) + '/helpers')

describe Mapel::Engine do
  describe "#try" do
    it "should allow sending invalid methods" do
      mapel = Mapel("someimage")
      mapel.try(:invalid_method).should == mapel
    end
  end
end
