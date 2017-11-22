module Microtest
  module PowerAssert
    class Evaluation
      getter expression : String
      getter value : Value

      def initialize(@expression, @value)
      end

      def_equals_and_hash expression
    end

    abstract class Value
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

      def initialize(@name, @expression, value : T) forall T
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

    class Call(B) < Node
      OPERATORS = %w(
        ! != % & * ** + - / < << <= <=> == === > >= >> ^ | ~
      )

      getter receiver : Node
      getter arguments : Array(Node)

      def initialize(name : String, expression : String, value : T,
                     @receiver : Node, @arguments : Array(Node),
                     @named_arguments : Array(NamedArg), @block : B) forall T
        super(name, expression, value)
      end

      def operator?
        name.in?(OPERATORS)
      end

      def nested_expressions : Array(Evaluation)
        result = [] of Evaluation

        result += receiver.nested_expressions

        result += arguments.map(&.nested_expressions).flatten

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
      def self.build(expression, value : T) forall T
        TerminalNode.new(expression, value)
      end

      @expression : String

      def initialize(expression, value)
        super(expression, expression, value)
      end

      def nested_expressions : Array(Evaluation)
        if expression == value.inspect
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
        # FIXME too much complex code, refactor into two methods, compact and complex or so
        expressions = node.nested_expressions.uniq
        complete_expression = expressions.last

        sizes = expressions.map do |ev|
          {left: ev.expression.size, right: ev.value.inspect.size}
        end

        max_sizes = sizes.reduce({left: 0, right: 0}) do |max, s|
          {
            left:  [max[:left], s[:left]].max,
            right: [max[:right], s[:right]].max,
          }
        end

        big_bar = "=" * 50
        small_bar = "-" * 50

        is_compact = max_sizes[:left] < 32 && max_sizes[:right] < 50

        exp_width = [8, 12, 16, 20, 24].find { |limit| max_sizes[:left] < limit } || 24

        assert_line = [
          "assert ".colorize(:red),
          complete_expression.expression.to_s.colorize(:yellow),
          " # ".colorize(:dark_gray),
          complete_expression.value.inspect.colorize(:dark_gray),
        ].join

        expression_values = expressions[0..-2].map do |ev|
          val = ev.value.inspect
          exp_str = if is_compact
                      "%-#{exp_width}s" % ev.expression
                    else
                      ev.expression.to_s
                    end

          [
            exp_str.colorize.fore(:yellow),
            (is_compact ? " => " : "\n").colorize(:light_blue),
            val,
            ("\n" + small_bar.colorize(:light_blue).to_s if !is_compact),
          ].join.colorize(:white)
        end.join("\n")

        [
          assert_line,
          if expressions.size > 1
            [
              big_bar.colorize(:light_blue),
              expression_values,
            ].join("\n")
          end,
        ].join("\n")
      end
    end

    macro reflect_terminal(expression)
      {% if expression.is_a? Call %}
        {% if expression.receiver.is_a?(Nop) %}
          %receiver = Microtest::PowerAssert::EmptyNode.new
        {% else %}
          %receiver = Microtest::PowerAssert::EmptyNode.new
        {% end %}
        %args = [] of Microtest::PowerAssert::Node
        {% for arg in expression.args %}
          %args.push(Microtest::PowerAssert::EmptyNode.new)
        {% end %}

        %named_args = [] of Microtest::PowerAssert::NamedArg

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

    macro reflect_ast(expression)
      {% if expression.is_a? Call %}
        {% if expression.receiver.is_a?(Nop) %}
          %receiver = Microtest::PowerAssert::EmptyNode.new
        {% else %}
          %receiver = reflect_terminal({{ expression.receiver }})
        {% end %}
        %args = [] of Microtest::PowerAssert::Node
        {% for arg in expression.args %}
          %args.push(reflect_terminal({{ arg }}))
        {% end %}

        %named_args = [] of Microtest::PowerAssert::NamedArg
        {% if expression.named_args.is_a?(ArrayLiteral) %}
          {% for key, idx in expression.named_args %}
            %named_args.push Microtest::PowerAssert::NamedArg.new(
              :{{ key.name.id }},
              reflect_terminal({{ expression.named_args[idx].value }})
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

        fail %message, {{ expression.filename }}, {{ expression.line_number }}
      end
    end

    def assert_raises(exception_type : Exception.class, file : String = __FILE__, line : String = __LINE__, &block)
      yield
    rescue e
      case e
      when exception_type
        pass
      else raise AssertionFailure.new("Expected block to raise #{exception_type} but it raised #{e.class}: #{e.inspect}", file, line)
      end
    else
      raise AssertionFailure.new("Expected block to raise #{exception_type} but it didn't", file, line)
    end
  end
end
