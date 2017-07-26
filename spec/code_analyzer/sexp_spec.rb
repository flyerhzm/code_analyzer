require 'spec_helper'

describe Sexp do
  describe "line" do
    before :each do
      content = <<-EOF
      class Demo
        def test
          ActiveRecord::Base.connection
        end
        alias :test_new :test
        CONST = { foo: :bar }
        def massign
          a, b = 10, 20
        end
        def opassign(a, b)
          a+= b
        end
        def condition
          if success?
            puts "unknown" if output?
          elsif fail?
          end
        end
      end
      EOF
      @node = parse_content(content)
    end

    it "should return class line" do
      expect(@node.grep_node(sexp_type: :class).line_number).to eq 1
    end

    it "should return def line" do
      expect(@node.grep_node(sexp_type: :def).line_number).to eq 2
    end

    it "should return const line" do
      expect(@node.grep_node(sexp_type: :const_ref).line_number).to eq 1
    end

    it "should return const path line" do
      expect(@node.grep_node(sexp_type: :const_path_ref).line_number).to eq 3
    end

    it "should return alias line" do
      expect(@node.grep_node(sexp_type: :alias).line_number).to eq 5
    end

    it "should return hash line" do
      expect(@node.grep_node(sexp_type: :hash).line_number).to eq 6
    end

    it "should return massign line" do
      expect(@node.grep_node(sexp_type: :massign).line_number).to eq 8
    end

    it "should return opassign line" do
      expect(@node.grep_node(sexp_type: :opassign).line_number).to eq 11
    end

    it "should return if line" do
      expect(@node.grep_node(sexp_type: :if).line_number).to eq 14
    end

    it "should return elsif line" do
      expect(@node.grep_node(sexp_type: :elsif).line_number).to eq 16
    end

    it "should return if_mod line" do
      expect(@node.grep_node(sexp_type: :if_mod).line_number).to eq 15
    end
  end

  describe "grep_nodes" do
    before :each do
      content = <<-EOF
      def show
        current_user.posts.find(params[:id])
      end
      EOF
      @node = parse_content(content)
    end

    it "should get the call nodes with receiver current_user" do
      nodes = []
      @node.grep_nodes(sexp_type: :call, receiver: "current_user") { |node| nodes << node }
      if RUBY_VERSION == "1.9.2"
        expect(nodes).to eq [s(:call, s(:var_ref, s(:@ident, "current_user", s(2, 8))), :".", s(:@ident, "posts", s(2, 21)))]
      else
        expect(nodes).to eq [s(:call, s(:vcall, s(:@ident, "current_user", s(2, 8))), :".", s(:@ident, "posts", s(2, 21)))]
      end
    end

    it "should get the call nodes with different messages" do
      nodes = []
      @node.grep_nodes(sexp_type: :call, message: ["posts", "find"]) { |node| nodes << node }
      if RUBY_VERSION == "1.9.2"
        expect(nodes).to eq [s(:call, s(:call, s(:var_ref, s(:@ident, "current_user", s(2, 8))), :".", s(:@ident, "posts", s(2, 21))), :".", s(:@ident, "find", s(2, 27))), s(:call, s(:var_ref, s(:@ident, "current_user", s(2, 8))), :".", s(:@ident, "posts", s(2, 21)))]
      else
        expect(nodes).to eq [s(:call, s(:call, s(:vcall, s(:@ident, "current_user", s(2, 8))), :".", s(:@ident, "posts", s(2, 21))), :".", s(:@ident, "find", s(2, 27))), s(:call, s(:vcall, s(:@ident, "current_user", s(2, 8))), :".", s(:@ident, "posts", s(2, 21)))]
      end
    end

    if RUBY_VERSION == "1.9.2"
      it "should get the var_ref node with to_s" do
        nodes = []
        @node.grep_nodes(sexp_type: :var_ref, to_s: "current_user") { |node| nodes << node }
        expect(nodes).to eq [s(:var_ref, s(:@ident, "current_user", s(2, 8)))]
      end
    else
      it "should get the vcall node with to_s" do
        nodes = []
        @node.grep_nodes(sexp_type: :vcall, to_s: "current_user") { |node| nodes << node }
        expect(nodes).to eq [s(:vcall, s(:@ident, "current_user", s(2, 8)))]
      end
    end
  end

  describe "grep_node" do
    before :each do
      content = <<-EOF
      def show
        current_user.posts.find(params[:id])
      end
      EOF
      @node = parse_content(content)
    end

    it "should get first node with empty argument" do
      node = @node.grep_node(sexp_type: :call, receiver: "current_user")
      if RUBY_VERSION == "1.9.2"
        expect(node).to eq s(:call, s(:var_ref, s(:@ident, "current_user", s(2, 8))), :".", s(:@ident, "posts", s(2, 21)))
      else
        expect(node).to eq s(:call, s(:vcall, s(:@ident, "current_user", s(2, 8))), :".", s(:@ident, "posts", s(2, 21)))
      end
    end
  end

  describe "grep_nodes_count" do
    before :each do
      content = <<-EOF
      def show
        current_user.posts.find(params[:id])
      end
      EOF
      @node = parse_content(content)
    end

    it "should get the count of call nodes" do
      expect(@node.grep_nodes_count(sexp_type: :call)).to eq 2
    end
  end

  describe "receiver" do
    it "should get receiver of assign node" do
      node = parse_content("user.name = params[:name]").grep_node(sexp_type: :assign)
      receiver = node.receiver
      expect(receiver.sexp_type).to eq :field
      expect(receiver.receiver.to_s).to eq "user"
      expect(receiver.message.to_s).to eq "name"
    end

    it "should get receiver of field node" do
      node = parse_content("user.name = params[:name]").grep_node(sexp_type: :field)
      expect(node.receiver.to_s).to eq "user"
    end

    it "should get receiver of call node" do
      node = parse_content("user.name").grep_node(sexp_type: :call)
      expect(node.receiver.to_s).to eq "user"
    end

    it "should get receiver of binary" do
      node = parse_content("user == 'user_name'").grep_node(sexp_type: :binary)
      expect(node.receiver.to_s).to eq "user"
    end

    it "should get receiver of command_call" do
      content = <<-EOF
      map.resources :posts do
      end
      EOF
      node = parse_content(content).grep_node(sexp_type: :command_call)
      expect(node.receiver.to_s).to eq "map"
    end

    it "should get receiver of method_add_arg" do
      node = parse_content("Post.find(:all)").grep_node(sexp_type: :method_add_arg)
      expect(node.receiver.to_s).to eq "Post"
    end

    it "should get receiver of method_add_block" do
      node = parse_content("Post.save do; end").grep_node(sexp_type: :method_add_block)
      expect(node.receiver.to_s).to eq "Post"
    end
  end

  describe "module_name" do
    it "should get module name of module node" do
      node = parse_content("module Admin; end").grep_node(sexp_type: :module)
      expect(node.module_name.to_s).to eq "Admin"
    end
  end

  describe "class_name" do
    it "should get class name of class node" do
      node = parse_content("class User; end").grep_node(sexp_type: :class)
      expect(node.class_name.to_s).to eq "User"
    end
  end

  describe "base_class" do
    it "should get base class of class node" do
      node = parse_content("class User < ActiveRecord::Base; end").grep_node(sexp_type: :class)
      expect(node.base_class.to_s).to eq "ActiveRecord::Base"
    end
  end

  describe "left_value" do
    it "should get the left value of assign" do
      node = parse_content("user = current_user").grep_node(sexp_type: :assign)
      expect(node.left_value.to_s).to eq "user"
    end
  end

  describe "right_value" do
    it "should get the right value of assign" do
      node = parse_content("user = current_user").grep_node(sexp_type: :assign)
      expect(node.right_value.to_s).to eq "current_user"
    end
  end

  describe "message" do
    it "should get the message of command" do
      node = parse_content("has_many :projects").grep_node(sexp_type: :command)
      expect(node.message.to_s).to eq "has_many"
    end

    it "should get the message of command_call" do
      node = parse_content("map.resources :posts do; end").grep_node(sexp_type: :command_call)
      expect(node.message.to_s).to eq "resources"
    end

    it "should get the message of field" do
      node = parse_content("user.name = 'test'").grep_node(sexp_type: :field)
      expect(node.message.to_s).to eq "name"
    end

    it "should get the message of call" do
      node = parse_content("user.name").grep_node(sexp_type: :call)
      expect(node.message.to_s).to eq "name"
    end

    it "should get the message of binary" do
      node = parse_content("user.name == 'test'").grep_node(sexp_type: :binary)
      expect(node.message.to_s).to eq "=="
    end

    it "should get the message of fcall" do
      node = parse_content("test?('world')").grep_node(sexp_type: :fcall)
      expect(node.message.to_s).to eq "test?"
    end

    it "should get the message of method_add_arg" do
      node = parse_content("Post.find(:all)").grep_node(sexp_type: :method_add_arg)
      expect(node.message.to_s).to eq "find"
    end

    it "should get the message of method_add_block" do
      node = parse_content("Post.save do; end").grep_node(sexp_type: :method_add_block)
      expect(node.message.to_s).to eq "save"
    end
  end

  describe "arguments" do
    it "should get the arguments of command" do
      node = parse_content("resources :posts do; end").grep_node(sexp_type: :command)
      expect(node.arguments.sexp_type).to eq :args_add_block
    end

    it "should get the arguments of command_call" do
      node = parse_content("map.resources :posts do; end").grep_node(sexp_type: :command_call)
      expect(node.arguments.sexp_type).to eq :args_add_block
    end

    it "should get the arguments of method_add_arg" do
      node = parse_content("User.find(:all)").grep_node(sexp_type: :method_add_arg)
      expect(node.arguments.sexp_type).to eq :args_add_block
    end

    it "should get the arguments of method_add_block" do
      node = parse_content("Post.save(false) do; end").grep_node(sexp_type: :method_add_block)
      expect(node.arguments.sexp_type).to eq :args_add_block
    end
  end

  describe "argument" do
    it "should get the argument of binary" do
      node = parse_content("user == current_user").grep_node(sexp_type: :binary)
      expect(node.argument.to_s).to eq "current_user"
    end
  end

  describe "all" do
    it "should get all arguments" do
      node = parse_content("puts 'hello', 'world'").grep_node(sexp_type: :args_add_block)
      expect(node.all.map(&:to_s)).to eq ["hello", "world"]
    end

    it "should get all arguments with &:" do
      node = parse_content("user.posts.map(&:title)").grep_node(sexp_type: :args_add_block)
      expect(node.all.map(&:to_s)).to eq ["title"]
    end

    it "should get all arguments with command_call node" do
      node = parse_content("options_for_select(Account.get_business current_user)").grep_node(sexp_type: :args_add)
      if RUBY_VERSION == "1.9.2"
        expect(node.all).to eq [s(:command_call, s(:var_ref, s(:@const, "Account", s(1, 19))), :".", s(:@ident, "get_business", s(1, 27)), s(:args_add_block, s(:args_add, s(:args_new), s(:var_ref, s(:@ident, "current_user", s(1, 40)))), false))]
      else
        expect(node.all).to eq [s(:command_call, s(:var_ref, s(:@const, "Account", s(1, 19))), :".", s(:@ident, "get_business", s(1, 27)), s(:args_add_block, s(:args_add, s(:args_new), s(:vcall, s(:@ident, "current_user", s(1, 40)))), false))]
      end
    end

    it "no error for args_add_star" do
      node = parse_content("send(:\"\#{route}_url\", *args)").grep_node(sexp_type: :args_add_block)
      expect { node.all }.not_to raise_error
    end
  end

  describe "conditional_statement" do
    it "should get conditional statement of if" do
      node = parse_content("if true; end").grep_node(sexp_type: :if)
      expect(node.conditional_statement.to_s).to eq "true"
    end

    it "should get conditional statement of unless" do
      node = parse_content("unless false; end").grep_node(sexp_type: :unless)
      expect(node.conditional_statement.to_s).to eq "false"
    end

    it "should get conditional statement of elsif" do
      node = parse_content("if true; elsif false; end").grep_node(sexp_type: :elsif)
      expect(node.conditional_statement.to_s).to eq "false"
    end

    it "should get conditional statement of if_mod" do
      node = parse_content("'OK' if true").grep_node(sexp_type: :if_mod)
      expect(node.conditional_statement.to_s).to eq "true"
    end

    it "should get conditional statement of unless_mod" do
      node = parse_content("'OK' unless false").grep_node(sexp_type: :unless_mod)
      expect(node.conditional_statement.to_s).to eq "false"
    end

    it "should get conditional statement of ifop" do
      node = parse_content("true ? 'OK' : 'NO'").grep_node(sexp_type: :ifop)
      expect(node.conditional_statement.to_s).to eq "true"
    end
  end

  describe "all_conditions" do
    it "should get all conditions" do
      node = parse_content("user == current_user && user.valid? || user.admin?").grep_node(sexp_type: :binary)
      expect(node.all_conditions.size).to eq 3
    end
  end

  describe "method_name" do
    it "should get the method name of def" do
      node = parse_content("def show; end").grep_node(sexp_type: :def)
      expect(node.method_name.to_s).to eq "show"
    end

    it "should get the method name of defs" do
      node = parse_content("def self.find; end").grep_node(sexp_type: :defs)
      expect(node.method_name.to_s).to eq "find"
    end
  end

  describe "body" do
    it "should get body of class" do
      node = parse_content("class User; end").grep_node(sexp_type: :class)
      expect(node.body.sexp_type).to eq :bodystmt
    end

    it "should get body of def" do
      node = parse_content("def login; end").grep_node(sexp_type: :def)
      expect(node.body.sexp_type).to eq :bodystmt
    end

    it "should get body of defs" do
      node = parse_content("def self.login; end").grep_node(sexp_type: :defs)
      expect(node.body.sexp_type).to eq :bodystmt
    end

    it "should get body of module" do
      node = parse_content("module Enumerable; end").grep_node(sexp_type: :module)
      expect(node.body.sexp_type).to eq :bodystmt
    end

    it "should get body of if" do
      node = parse_content("if true; 'OK'; end").grep_node(sexp_type: :if)
      expect(node.body.sexp_type).to eq :stmts_add
    end

    it "should get body of elsif" do
      node = parse_content("if true; elsif true; 'OK'; end").grep_node(sexp_type: :elsif)
      expect(node.body.sexp_type).to eq :stmts_add
    end

    it "should get body of unless" do
      node = parse_content("unless true; 'OK'; end").grep_node(sexp_type: :unless)
      expect(node.body.sexp_type).to eq :stmts_add
    end

    it "should get body of else" do
      node = parse_content("if true; else; 'OK'; end").grep_node(sexp_type: :else)
      expect(node.body.sexp_type).to eq :stmts_add
    end

    it "should get body of if_mod" do
      node = parse_content("'OK' if true").grep_node(sexp_type: :if_mod)
      expect(node.body.to_s).to eq "OK"
    end

    it "should get body of unless_mod" do
      node = parse_content("'OK' unless false").grep_node(sexp_type: :unless_mod)
      expect(node.body.to_s).to eq "OK"
    end

    it "should get body of if_op" do
      node = parse_content("true ? 'OK' : 'NO'").grep_node(sexp_type: :ifop)
      expect(node.body.to_s).to eq "OK"
    end
  end

  describe "block" do
    it "sould get block of method_add_block node" do
      node = parse_content("resources :posts do; resources :comments; end").grep_node(sexp_type: :method_add_block)
      expect(node.block_node.sexp_type).to eq :do_block
    end
  end

  describe "statements" do
    it "should get statements of do_block node" do
      node = parse_content("resources :posts do; resources :comments; resources :like; end").grep_node(sexp_type: :do_block)
      expect(node.statements.size).to eq 2
    end

    it "should get statements of bodystmt node" do
      node = parse_content("class User; def login?; end; def admin?; end; end").grep_node(sexp_type: :bodystmt)
      expect(node.statements.size).to eq 2
    end
  end

  describe "exception_classes" do
    it "should get exception classes of rescue node" do
      node = parse_content("def test; rescue CustomException; end").grep_node(sexp_type: :rescue)
      expect(node.exception_classes.first.to_s).to eq "CustomException"
    end

    it "should get empty of empty rescue node" do
      node = parse_content("def test; rescue; end").grep_node(sexp_type: :rescue)
      expect(node.exception_classes.first.to_s).to eq ""
    end

    it "should get exception classes of rescue node for multiple exceptions" do
      node = parse_content("def test; rescue StandardError, CustomException; end").grep_node(sexp_type: :rescue)
      expect(node.exception_classes.first.to_s).to eq "StandardError"
      expect(node.exception_classes.last.to_s).to eq "CustomException"
    end
  end

  describe "exception_variable" do
    it "should get exception varible of rescue node" do
      node = parse_content("def test; rescue => e; end").grep_node(sexp_type: :rescue)
      expect(node.exception_variable.to_s).to eq "e"
    end

    it "should get empty of empty rescue node" do
      node = parse_content("def test; rescue; end").grep_node(sexp_type: :rescue)
      expect(node.exception_variable.to_s).to eq ""
    end
  end

  describe "hash_value" do
    it "should get value for hash node" do
      node = parse_content("{first_name: 'Richard', last_name: 'Huang'}").grep_node(sexp_type: :hash)
      expect(node.hash_value("first_name").to_s).to eq "Richard"
      expect(node.hash_value("last_name").to_s).to eq "Huang"
    end

    it "should get value for bare_assoc_hash" do
      node = parse_content("add_user :user, first_name: 'Richard', last_name: 'Huang'").grep_node(sexp_type: :bare_assoc_hash)
      expect(node.hash_value("first_name").to_s).to eq "Richard"
      expect(node.hash_value("last_name").to_s).to eq "Huang"
    end
  end

  describe "hash_size" do
    it "should get value for hash node" do
      node = parse_content("{first_name: 'Richard', last_name: 'Huang'}").grep_node(sexp_type: :hash)
      expect(node.hash_size).to eq 2
    end

    it "should get value for bare_assoc_hash" do
      node = parse_content("add_user :user, first_name: 'Richard', last_name: 'Huang'").grep_node(sexp_type: :bare_assoc_hash)
      expect(node.hash_size).to eq 2
    end
  end

  describe "hash_keys" do
    it "should get hash_keys for hash node" do
      node = parse_content("{first_name: 'Richard', last_name: 'Huang'}").grep_node(sexp_type: :hash)
      expect(node.hash_keys).to eq ["first_name", "last_name"]
    end

    it "should get hash_keys for bare_assoc_hash" do
      node = parse_content("add_user :user, first_name: 'Richard', last_name: 'Huang'").grep_node(sexp_type: :bare_assoc_hash)
      expect(node.hash_keys).to eq ["first_name", "last_name"]
    end
  end

  describe "hash_values" do
    it "should get hash_values for hash node" do
      node = parse_content("{first_name: 'Richard', last_name: 'Huang'}").grep_node(sexp_type: :hash)
      expect(node.hash_values.map(&:to_s)).to eq ["Richard", "Huang"]
    end

    it "should get hash_values for bare_assoc_hash" do
      node = parse_content("add_user :user, first_name: 'Richard', last_name: 'Huang'").grep_node(sexp_type: :bare_assoc_hash)
      expect(node.hash_values.map(&:to_s)).to eq ["Richard", "Huang"]
    end
  end

  describe "array_size" do
    it "should get array size" do
      node = parse_content("['first_name', 'last_name']").grep_node(sexp_type: :array)
      expect(node.array_size).to eq 2
    end

    it "should get 0" do
      node = parse_content("[]").grep_node(sexp_type: :array)
      expect(node.array_size).to eq 0
    end
  end

  describe "array_values" do
    it "should get array values" do
      node = parse_content("['first_name', 'last_name']").grep_node(sexp_type: :array)
      expect(node.array_values.map(&:to_s)).to eq ["first_name", "last_name"]
    end

    it "should get empty array values" do
      node = parse_content("[]").grep_node(sexp_type: :array)
      expect(node.array_values).to eq []
    end

    it "should get array value with array and words_add" do
      node = parse_content("%W{day week fortnight}").grep_node(sexp_type: :array)
      expect(node.array_values.map(&:to_s)).to eq ["day", "week", "fortnight"]
    end

    it "should get empty array values with array and words_add" do
      node = parse_content("%W{}").grep_node(sexp_type: :array)
      expect(node.array_values.map(&:to_s)).to eq []
    end

    it "should get array value with array and qwords_add" do
      node = parse_content("%w(first_name last_name)").grep_node(sexp_type: :array)
      expect(node.array_values.map(&:to_s)).to eq ["first_name", "last_name"]
    end

    it "should get empty array values with array and qwords_add" do
      node = parse_content("%w()").grep_node(sexp_type: :array)
      expect(node.array_values.map(&:to_s)).to eq []
    end

    if RUBY_VERSION.to_i > 1
      it "should get array value with array and symbols_add" do
        node = parse_content("%I(first_name last_name)").grep_node(sexp_type: :array)
        expect(node.array_values.map(&:to_s)).to eq ["first_name", "last_name"]
      end

      it "should get empty array value with array and symbols_add" do
        node = parse_content("%I()").grep_node(sexp_type: :array)
        expect(node.array_values.map(&:to_s)).to eq []
      end

      it "should get array value with array and qsymbols_add" do
        node = parse_content("%i(first_name last_name)").grep_node(sexp_type: :array)
        expect(node.array_values.map(&:to_s)).to eq ["first_name", "last_name"]
      end

      it "should get empty array values with array and qsymbols_new" do
        node = parse_content("%i()").grep_node(sexp_type: :array)
        expect(node.array_values.map(&:to_s)).to eq []
      end
    end
  end

  describe "alias" do
    context "method" do
      before do
        @node = parse_content("alias new old").grep_node(sexp_type: :alias)
      end

      it "should get old_method" do
        expect(@node.old_method.to_s).to eq "old"
      end

      it "should get new_method" do
        expect(@node.new_method.to_s).to eq "new"
      end
    end

    context "symbol" do
      before do
        @node = parse_content("alias :new :old").grep_node(sexp_type: :alias)
      end

      it "should get old_method" do
        expect(@node.old_method.to_s).to eq "old"
      end

      it "should get new_method" do
        expect(@node.new_method.to_s).to eq "new"
      end
    end
  end

  describe "to_object" do
    it "should to array" do
      node = parse_content("['first_name', 'last_name']").grep_node(sexp_type: :array)
      expect(node.to_object).to eq ["first_name", "last_name"]
    end

    it "should to array with %w()" do
      node = parse_content("%w(new create)").grep_node(sexp_type: :array)
      expect(node.to_object).to eq ["new", "create"]
    end

    it "should to array with symbols" do
      node = parse_content("[:first_name, :last_name]").grep_node(sexp_type: :array)
      expect(node.to_object).to eq ["first_name", "last_name"]
    end

    it "should to empty array" do
      node = parse_content("[]").grep_node(sexp_type: :array)
      expect(node.to_object).to eq []
    end

    it "should to string" do
      node = parse_content("'richard'").grep_node(sexp_type: :string_literal)
      expect(node.to_object).to eq "richard"
    end
  end

  describe "to_s" do
    it "should get to_s for string" do
      node = parse_content("'user'").grep_node(sexp_type: :string_literal)
      expect(node.to_s).to eq "user"
    end

    it "should get to_s for symbol" do
      node = parse_content(":user").grep_node(sexp_type: :symbol_literal)
      expect(node.to_s).to eq "user"
    end

    it "should get to_s for const" do
      node = parse_content("User").grep_node(sexp_type: :@const)
      expect(node.to_s).to eq "User"
    end

    it "should get to_s for ivar" do
      node = parse_content("@user").grep_node(sexp_type: :@ivar)
      expect(node.to_s).to eq "@user"
    end

    it "should get to_s for class with module" do
      node = parse_content("ActiveRecord::Base").grep_node(sexp_type: :const_path_ref)
      expect(node.to_s).to eq "ActiveRecord::Base"
    end

    it "should get to_s for label" do
      node = parse_content("{first_name: 'Richard'}").grep_node(sexp_type: :@label)
      expect(node.to_s).to eq "first_name"
    end

    it "should get to_s for call" do
      node = parse_content("current_user.post").grep_node(sexp_type: :call)
      expect(node.to_s).to eq "current_user.post"
    end

    it "should get to_s for top_const_ref" do
      node = parse_content("::User").grep_node(sexp_type: :top_const_ref)
      expect(node.to_s).to eq "::User"
    end
  end

  describe "const?" do
    it "should return true for const with var_ref" do
      node = parse_content("User.find").grep_node(sexp_type: :var_ref)
      expect(node).to be_const
    end

    it "should return true for const with @const" do
      node = parse_content("User.find").grep_node(sexp_type: :@const)
      expect(node).to be_const
    end

    it "should return false for ivar" do
      node = parse_content("@user.find").grep_node(sexp_type: :@ivar)
      expect(node).not_to be_const
    end
  end

  describe "present?" do
    it "should return true" do
      node = parse_content("hello world")
      expect(node).to be_present
    end
  end

  describe "blank?" do
    it "should return false" do
      node = parse_content("hello world")
      expect(node).not_to be_blank
    end
  end

  describe "remove_line_and_column" do
    it "should remove" do
      s(:@ident, "test", s(2, 12)).remove_line_and_column.should_equal s(:@ident, "test")
    end

    it "should remove child nodes" do
      s(:const_ref, s(:@const, "Demo", s(1, 12))).remove_line_and_column.should_equal s(:const_def, s(:@const, "Demo"))
    end
  end
end
