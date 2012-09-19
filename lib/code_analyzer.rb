# encoding: utf-8
require "ripper"
require "code_analyzer/version"
require "code_analyzer/nil"
require "code_analyzer/sexp"

module CodeAnalyzer
   autoload :AnalyzerException, "code_analyzer/analyzer_exception"
   autoload :Checker, "code_analyzer/checker"
   autoload :CheckingVisitor, "code_analyzer/checking_visitor"
   autoload :Warning, "code_analyzer/warning"
end
