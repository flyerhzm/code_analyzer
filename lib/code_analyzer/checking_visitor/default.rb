# encoding: utf-8
module CodeAnalyzer::CheckingVisitor
  # This is the default checking visitor to check ruby sexp nodes.
  class Default < Base
    def initialize(options={})
      super
      @checks = {}
      @checkers.each do |checker|
        checker.interesting_nodes.each do |node|
          @checks[node] ||= []
          @checks[node] << checker
          @checks[node].uniq!
        end
      end
   end

    # check the ruby sexp nodes for the ruby file.
    #
    # @param [String] filename is the filename of ruby code.
    # @param [String] content is the content of ruby file.
    def check(filename, content)
      node = parse(filename, content)
      node.file = filename
      check_node(node)
    end

    # trigger all after_check callbacks defined in all checkers.
    def after_check
      @checkers.each do |checker|
        after_check_callbacks = checker.class.get_callbacks(:after_check)
        after_check_callbacks.each do |block|
          checker.instance_exec &block
        end
      end
    end

    # parse ruby code.
    #
    # @param [String] filename is the filename of ruby code.
    # @param [String] content is the content of ruby file.
    def parse(filename, content)
      Sexp.from_array(Ripper::SexpBuilder.new(content).parse)
    rescue Exception
      raise AnalyzerException.new("#{filename} looks like it's not a valid Ruby file.  Skipping...")
    end

    # recursively check ruby sexp node.
    #
    # 1. it triggers the interesting checkers' start callbacks.
    # 2. recursively check the sexp children.
    # 3. it triggers the interesting checkers' end callbacks.
    def check_node(node)
      checkers = @checks[node.sexp_type]
      if checkers
        checkers.each { |checker| checker.node_start(node) if checker.parse_file?(node.file) }
      end
      node.children.each { |child_node|
        child_node.file = node.file
        child_node.check(self)
      }
      if checkers
        checkers.each { |checker| checker.node_end(node) if checker.parse_file?(node.file) }
      end
    end
  end
end
