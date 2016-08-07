require 'spec_helper'

module CodeAnalyzer
  describe Checker do
    let(:checker) { Checker.new }

    context "interesting_nodes" do
      it "should get empty interesting nodes" do
        expect(checker.interesting_nodes).to eq []
      end

      it "should add interesting nodes" do
        Checker.interesting_nodes :class, :def
        expect(checker.interesting_nodes).to eq [:class, :def]
      end
    end

    context "interesting_files" do
      it "should match none of interesting files" do
        expect(checker.interesting_files).to eq []
      end

      it "should add interesting files" do
        Checker.interesting_files /lib/, /spec/
        expect(checker.interesting_files).to eq [/lib/, /spec/]
      end
    end

    context "#parse_file?" do
      it "should return true if node_file matches pattern" do
        allow(checker).to receive(:interesting_files).and_return([/spec\/.*\.rb/, /lib\/.*\.rb/])
        expect(checker.parse_file?("lib/code_analyzer.rb")).to be true
      end

      it "should return false if node_file doesn't match pattern" do
        allow(checker).to receive(:interesting_files).and_return([/spec\/.*\.rb/])
        expect(checker.parse_file?("lib/code_analyzer.rb")).to be false
      end
    end

    context "callback" do
      it "should add callback to start_call" do
        block = Proc.new {}
        Checker.add_callback(:start_call, &block)
        expect(Checker.get_callbacks(:start_call)).to eq [block]
      end

      it "should add callback to both start_class and end_class" do
        block = Proc.new {}
        Checker.add_callback(:start_class, :end_class, &block)
        expect(Checker.get_callbacks(:start_class)).to eq [block]
        expect(Checker.get_callbacks(:end_class)).to eq [block]
      end

      it "should add multiple callbacks to end_call" do
        block1 = Proc.new {}
        block2 = Proc.new {}
        Checker.add_callback(:end_call, &block1)
        Checker.add_callback(:end_call, &block2)
        expect(Checker.get_callbacks(:end_call)).to eq [block1, block2]
      end
    end
  end
end
