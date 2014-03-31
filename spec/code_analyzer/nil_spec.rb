require 'spec_helper'

module CodeAnalyzer
  describe Nil do
    let(:core_nil) { Nil.new }

    context "to_s" do
      it "should return self" do
        expect(core_nil.to_s).to eq core_nil
      end
    end

    context "hash_size" do
      it "should return 0" do
        expect(core_nil.hash_size).to eq 0
      end
    end

    context "method_missing" do
      it "should return self" do
        expect(core_nil.undefined).to eq core_nil
      end
    end

    context "present?" do
      it "should return false" do
        expect(core_nil).not_to be_present
      end
    end

    context "blank?" do
      it "should return true" do
        expect(core_nil).to be_blank
      end
    end
  end
end
