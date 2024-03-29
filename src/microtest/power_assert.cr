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

      # See performance warning in formatter
      def inspect(io)
        value.inspect(io)
      end
    end

    abstract class Node
      getter expression : String
      getter wrapper : Value

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
      getter method_name : String
      getter receiver : Node
      getter arguments : Array(Node)

      def initialize(@method_name : String, expression : String, value : T,
                     @receiver : Node, @arguments : Array(Node),
                     @named_arguments : Array(NamedArgNode)) forall T
        super(expression, value)
      end

      def_equals_and_hash method_name, expression, wrapper, receiver, arguments, @named_arguments # , @block

      def operator?
        method_name.in?(%w(! != % & * ** + - / < << <= <=> == === > >= >> ^ | ~))
      end

      def comparator?
        method_name.in?(%w(!= < <= <=> == === > >=))
      end
    end

    class NamedArgNode < Node
      getter name : String

      # FIXME implement
      def initialize(@name, value)
        super("", value)
      end

      def_equals_and_hash name, expression, wrapper
    end

    class TerminalNode < Node
      def initialize(expression : String, value : T) forall T
        super(expression, value)
      end

      def_equals_and_hash expression, wrapper
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

        # This tuple will contain the actual values, not reflection-nodes (NamedArgNode)
        # We need this to pass it to the actual invocation of the Call
        %na = NamedTuple.new

        {% if expression.named_args.is_a?(ArrayLiteral) %}
          {% for arg in expression.named_args %}
            %v = Microtest::PowerAssert.reflect_tuple({{ arg.value }})

            # merge all of the tuples into one
            %na = %na.merge({ {{ arg.name }}: %v[:value] })

            %named_args.push(Microtest::PowerAssert::NamedArgNode.new(
              {{ arg.name.stringify }},
              %v[:node]
            ))
          {% end %}
        {% end %}

        %value = {% if expression.receiver.is_a?(Nop) %}
            {{expression.name}}(*%arg_vals, **%na) {{expression.block}}
          {% else %}
            %receiver[:value].{{expression.name}}(*%arg_vals, **%na) {{expression.block}}
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

    macro assert(expression)
      %result = Microtest::PowerAssert.reflect_tuple({{ expression }})

      if %result[:value]
        pass
      else
        %ast = %result[:node]

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
