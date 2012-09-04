# -*- encoding: utf-8 -*-
require File.expand_path('../lib/code_analyzer/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Richard Huang"]
  gem.email         = ["flyerhzm@gmail.com"]
  gem.description   = %q{TODO: Write a gem description}
  gem.summary       = %q{TODO: Write a gem summary}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "code_analyzer"
  gem.require_paths = ["lib"]
  gem.version       = CodeAnalyzer::VERSION

  gem.add_dependency "sexp_processor"
  gem.add_development_dependency "rspec"
end
