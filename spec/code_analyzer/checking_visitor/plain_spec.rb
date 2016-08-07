require "spec_helper"

module CodeAnalyzer::CheckingVisitor
  describe Plain do
    let(:checker1) { double(:checker) }
    let(:checker2) { double(:checker) }
    let(:visitor) { Plain.new(checkers: [checker1, checker2]) }

    it "should check by all checkers" do
      filename = "filename"
      content = "content"
      expect(checker1).to receive(:parse_file?).and_return(false)
      expect(checker2).to receive(:parse_file?).and_return(true)
      expect(checker1).not_to receive(:check).with(filename, content)
      expect(checker2).to receive(:check).with(filename, content)

      visitor.check(filename, content)
    end
  end
end
