# encoding: utf-8
module CodeAnalyzer
  module CheckingVisitor
    autoload :Base, "code_analyzer/checking_visitor/base"
    autoload :Plain, "code_analyzer/checking_visitor/plain"
    autoload :Default, "code_analyzer/checking_visitor/default"
  end
end
