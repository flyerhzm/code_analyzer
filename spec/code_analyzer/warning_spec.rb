require 'spec_helper'

module CodeAnalyzer
  describe Warning do
    it "should return error with filename, line number and message" do

      expect(Warning.new(
              filename: "app/models/user.rb",
              line_number: "100",
              message: "not good").to_s).to eq "app/models/user.rb:100 - not good"
    end
  end
end
