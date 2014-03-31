require "spec_helper"

module CodeAnalyzer::CheckingVisitor
  describe Default do
    let(:checker1) { double(:checker, interesting_nodes: [:class, :def]) }
    let(:checker2) { double(:checker, interesting_nodes: [:def, :call]) }
    let(:visitor) { Default.new(checkers: [checker1, checker2]) }

    it "should check def node by all checkers" do
      filename = "filename"
      content = "def test; end"
      allow(checker1).to receive(:parse_file?).with(filename).and_return(true)
      allow(checker2).to receive(:parse_file?).with(filename).and_return(true)
      expect(checker1).to receive(:node_start)
      expect(checker1).to receive(:node_end)
      expect(checker2).to receive(:node_start)
      expect(checker2).to receive(:node_end)

      visitor.check(filename, content)
    end

    it "should check class node by only checker1" do
      filename = "filename"
      content = "class Test; end"
      allow(checker1).to receive(:parse_file?).with(filename).and_return(true)
      expect(checker1).to receive(:node_start)
      expect(checker1).to receive(:node_end)

      visitor.check(filename, content)
    end

    it "should check call node by only checker2" do
      filename = "filename"
      content = "obj.message"
      allow(checker2).to receive(:parse_file?).with(filename).and_return(true)
      expect(checker2).to receive(:node_start)
      expect(checker2).to receive(:node_end)

      visitor.check(filename, content)
    end
  end
end
