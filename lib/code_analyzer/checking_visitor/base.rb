# frozen_string_literal: true

module CodeAnalyzer::CheckingVisitor
  # Base class for checking visitor.
  class Base
    def initialize(options = {})
      @checkers = options[:checkers]
    end

    def after_check; end

    def warnings
      @warnings ||= @checkers.map(&:warnings).flatten
    end
  end
end
