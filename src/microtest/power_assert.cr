module Microtest
  module PowerAssert
    abstract class Value
    end

    # There is no "Object" class in crystal, so we have to use this wrapper
    class ValueWrapper(T) < Value
      getter value : T

      def initialize(@value)
      end

      def_equals_and_hash value
    end

    abstract class Node
      getter expression : String
      getter wrapper : Value
      delegate value, to: wrapper

      def initialize(@expression, value : T) forall T
        @wrapper = ValueWrapper(T).new(value)
      end

      def_equals_and_hash expression, wrapper
    end

    class EmptyNode < Node
      def initialize
        super("", nil)
      end
    end

    class CallNode < Node
      OPERATORS = %w(
        ! != % & * ** + - / < << <= <=> == === > >= >> ^ | ~
      )

      getter method_name : String
      getter receiver : Node
      getter arguments : Array(Node)

      def initialize(@method_name : String, expression : String, value : T,
                     @receiver : Node, @arguments : Array(Node),
                     @named_arguments : Array(NamedArgNode)) forall T
        super(expression, value)
      end

      def operator?
        method_name.in?(OPERATORS)
      end

      def comparator?
        method_name.in?(%w(!= < <= <=> == === > >=))
      end

      def_equals_and_hash method_name, expression, value, receiver, arguments, @named_arguments # , @block
    end

    class NamedArgNode < Node
      getter name : String

      # FIXME implement
      def initialize(@name, value)
        super("", value)
      end
    end

    class TerminalNode < Node
      def initialize(expression : String, value : T) forall T
        super(expression, value)
      end

      def_equals_and_hash expression, value
    end

    # In order to evaluate the expression only once, and not multiple times,
    # we have to return a tuple of node and value, so that the returned values
    # can be used in calls without having to re-evaluate them.
    macro reflect_tuple(expression)
      {% if expression.is_a?(Call) %}

        {% if expression.receiver.is_a?(Nop) %}
          %receiver = {
            node: Microtest::PowerAssert::EmptyNode.new,
            value: nil
          }
        {% else %}
          %receiver = Microtest::PowerAssert.reflect_tuple({{ expression.receiver }})
        {% end %}

        %args = Tuple.new(
          {% for arg in expression.args %}
            Microtest::PowerAssert.reflect_tuple({{ arg }}),
          {% end %}
        )

        %arg_vals = %args.map(&.[:value])
        %arg_nodes = {% if expression.args.size > 0 %}
            %args.map(&.[:node].as(Microtest::PowerAssert::Node)).to_a
          {% else %}
            [] of Microtest::PowerAssert::Node
          {% end %}


        %named_args = [] of Microtest::PowerAssert::NamedArgNode

        {% if expression.named_args.is_a?(ArrayLiteral) %}
          {% for arg in expression.named_args %}
            %named_args.push Microtest::PowerAssert::NamedArgNode.new(
              {{ arg.name }},
              Microtest::PowerAssert.reflect_tuple({{ arg.value }})
            )
          {% end %}
        {% end %}

        %value = {% if expression.receiver.is_a?(Nop) %}
            {{expression.name}}(*%arg_vals) {{expression.block}}
          {% else %}
            %receiver[:value].{{expression.name}}(*%arg_vals) {{expression.block}}
          {% end %}

        {
          node: Microtest::PowerAssert::CallNode.new(
            {{ expression.name.stringify }},
            {{expression.stringify}},
            %value,
            %receiver[:node],
            %arg_nodes,
            %named_args
          ),
          value: %value
        }
      {% else %}
        %value = {{expression}}
        {
          node: Microtest::PowerAssert::TerminalNode.new(
            {{expression.stringify}},
            %value
          ),
          value: %value
        }
      {% end %}
    end

    macro reflect(expression)
      (Microtest::PowerAssert.reflect_tuple({{expression}}))[:node]
    end

    macro assert(expression, file = __FILE__, line = __LINE__)
      %result = {{ expression }}

      if %result
        pass
      else
        %ast = reflect({{ expression }})

        %message = Microtest.power_assert_formatter.call(%ast)

        fail(%message, {{ expression.filename }}, {{ expression.line_number }})
      end
    end

    def assert_raises(exception_type : E.class, file : String = __FILE__, line : String = __LINE__, &block) forall E
      yield
    rescue e : E
      pass
    rescue e
      raise AssertionFailure.new("Expected block to raise #{E.name} but it raised #{e.class.name}: #{e.inspect}", file, line)
    else
      raise AssertionFailure.new("Expected block to raise #{E.name} but it didn't", file, line)
    end
  end
end
