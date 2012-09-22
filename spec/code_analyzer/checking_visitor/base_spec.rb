require 'spec_helper'

module CodeAnalyzer
  module CheckingVisitor
    describe Base do
      it "should return all checkers' warnings" do
        warning1 = Warning.new
        checker1 = mock(:checker, warnings: [warning1])
        warning2 = Warning.new
        checker2 = mock(:checker, warnings: [warning2])
        visitor = Base.new(checkers: [checker1, checker2])
        visitor.warnings.should == [warning1, warning2]
      end
    end
  end
end
