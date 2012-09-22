# encoding: utf-8
module CodeAnalyzer::CheckingVisitor
  # Base class for checking visitor.
  class Base
    def initialize(options={})
      @checkers = options[:checkers]
    end

    def after_check; end

    def warnings
      @warnings ||= @checkers.map(&:warnings).flatten
    end
  end
end
