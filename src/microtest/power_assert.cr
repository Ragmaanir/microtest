module Microtest
  module PowerAssert
    class Evaluation
      getter expression : String
      getter value : Value

      def initialize(@expression, @value)
      end

      def ==(other : Evaluation)
        expression == other.expression
      end

      def hash
        0
      end
    end

    abstract class Value
      def self.build(value : T)
        ValueWrapper(T).new(value)
      end
    end

    class ValueWrapper(T) < Value
      getter value : T

      def initialize(@value)
      end

      def to_s(io)
        io << value.to_s
      end

      def inspect(io)
        io << value.inspect
      end
    end

    abstract class Node
      getter name : String
      getter expression : String
      getter value : Value

      def initialize(@name, @expression, value : T)
        @value = ValueWrapper(T).new(value)
      end

      abstract def nested_expressions : Array(Evaluation)
    end

    class EmptyNode < Node
      def initialize
        super("", "", nil)
      end

      def nested_expressions : Array(Evaluation)
        [] of Evaluation
      end
    end

    class Call(T, B) < Node
      OPERATORS = %w(
        ! != % & * ** + - / < << <= <=> == === > >= >> ^ | ~
      )

      getter receiver : Node
      getter arguments : Array(Node)

      def initialize(name : String, expression : String, value : T,
                     @receiver : Node, @arguments : Array(Node),
                     @named_arguments : Array(NamedArg), @block : B)
        super(name, expression, value)
      end

      def operator?
        name.in?(OPERATORS)
      end

      def nested_expressions : Array(Evaluation)
        result = [] of Evaluation

        result += receiver.nested_expressions

        # result += arguments.map(&.nested_expressions).flatten
        result += arguments.map(&.nested_expressions).reduce([] of Evaluation) { |list, exps| list + exps }

        result << Evaluation.new(expression, value)

        result
      end
    end

    class NamedArg < Node
      # FIXME implement
      def initialize(name, value)
        super("", value)
      end

      def nested_expressions : Array(Evaluation)
        [] of Evaluation
      end
    end

    class TerminalNode < Node
      def self.build(expression, value : T)
        TerminalNode.new(expression, value)
      end

      @expression : String

      def initialize(expression, value)
        super(expression, expression, value)
      end

      def nested_expressions : Array(Evaluation)
        if expression == value.to_s
          [] of Evaluation
        else
          [Evaluation.new(expression, value)] of Evaluation
        end
      end
    end

    abstract class Formatter
      abstract def call(node : Node)
    end

    class ListFormatter < Formatter
      def call(node : Node)
        node.nested_expressions.uniq.map do |ev|
          "%-16s : %s" % [ev.expression, ev.value.inspect]
        end.join("\n")
      end
    end

    macro reflect_ast(expression)
      {% if expression.is_a? Call %}
        {% if expression.receiver.is_a?(Nop) %}
          %receiver = Microtest::PowerAssert::EmptyNode.new
        {% else %}
          %receiver = reflect_ast({{ expression.receiver }})
        {% end %}
        %args = [] of Microtest::PowerAssert::Node
        {% for arg in expression.args %}
          %args.push(reflect_ast({{ arg }}))
        {% end %}

        %named_args = [] of Microtest::PowerAssert::NamedArg
        {% if expression.named_args.is_a?(ArrayLiteral) %}
          {% for key, idx in expression.named_args %}
            %named_args.push Microtest::PowerAssert::NamedArg.new(
              :{{ key.name.id }},
              reflect_ast({{ expression.named_args[idx].value }})
            )
          {% end %}
        {% end %}

        %block = {{ expression.block.stringify }}

        Microtest::PowerAssert::Call.new(
          {{ expression.name.stringify }}, {{expression.stringify}},
          {{ expression }},
          %receiver, %args, %named_args, %block
        )
      {% elsif expression.is_a? StringLiteral %}
        Microtest::PowerAssert::TerminalNode.build({{expression.id.stringify}}.inspect, {{expression}})
      {% elsif %w(SymbolLiteral RangeLiteral).includes?(expression.class_name) %}
        Microtest::PowerAssert::TerminalNode.build({{expression}}.inspect, {{expression}})
      {% else %}
        Microtest::PowerAssert::TerminalNode.build({{expression.id.stringify}}, {{expression}})
      {% end %}
    end

    macro assert(expression, file = __FILE__, line = __LINE__)
      %result = {{ expression }}

      if %result
        pass
      else
        %ast = reflect_ast({{ expression }})

        %message = Microtest.power_assert_formatter.call(%ast)

        fail %message, {{ file }}, {{ line }}
      end
    end

    def assert_raises(exception_type : Exception.class, file : String = __FILE__, line : String = __LINE__, &block)
      yield
    rescue exception_type
      pass
    else
      raise AssertionFailure.new("Expected block to raise #{exception_type} but it didn't", file, line)
    end
  end
end
