# frozen_string_literal: true

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'rspec'
require 'code_analyzer'

RSpec.configure do |config|
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true
end

def parse_content(content)
  Sexp.from_array(Ripper::SexpBuilder.new(content).parse)[1]
end
