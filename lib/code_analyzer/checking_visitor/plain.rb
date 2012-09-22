# encoding: utf-8
module CodeAnalyzer::CheckingVisitor
  # This is the checking visitor to check ruby plain code.
  class Plain < Base
    # check the ruby plain code.
    #
    # @param [String] filename is the filename of ruby code.
    # @param [String] content is the content of ruby file.
    def check(filename, content)
      @checkers.each do |checker|
        checker.check(filename, content)
      end
    end
  end
end
