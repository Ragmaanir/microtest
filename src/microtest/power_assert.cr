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

    # There is no "Object" class in crystal, so we have to use this wrapper
    class ValueWrapper(T) < Value
      getter value : T

      def initialize(@value)
      end

      # def to_s(io)
      #   value.to_s(io)
      # end

      # def inspect(io)
      #   value.inspect(io)
      # end

      def_equals_and_hash value
    end

    abstract class Node
      getter expression : String
      getter value : Value

      def initialize(@expression, value : T) forall T
        @value = ValueWrapper(T).new(value)
      end

      abstract def nested_expressions : Array(Evaluation)
    end

    class EmptyNode < Node
      def initialize
        super("", nil)
      end

      def nested_expressions : Array(Evaluation)
        [] of Evaluation
      end

      def_equals_and_hash
    end

    class Call < Node
      OPERATORS = %w(
        ! != % & * ** + - / < << <= <=> == === > >= >> ^ | ~
      )

      macro build(expression, nest)
        {%
          if expression.is_a?(Crystal::Macros::Call)
            raise "Expression is not a Call: #{expression}"
          end
        %}

        {% if !nest || expression.receiver.is_a?(Nop) %}
          %receiver = Microtest::PowerAssert::EmptyNode.new
        {% else %}
          %receiver = Microtest::PowerAssert.reflect(
            {{ expression.receiver }},
            nest
          )
        {% end %}

        %args = [] of Microtest::PowerAssert::Node

        {% for arg in expression.args %}
          %args.push(Microtest::PowerAssert.reflect({{ arg }}, nest))
        {% end %}

        %named_args = [] of Microtest::PowerAssert::NamedArg

        {% if expression.named_args.is_a?(ArrayLiteral) %}
          {% for arg in expression.named_args %}
            %named_args.push Microtest::PowerAssert::NamedArg.new(
              {{ arg.name }},
              reflect({{ arg.value }}, nest)
            )
          {% end %}
        {% end %}

        Microtest::PowerAssert::Call.new(
          {{ expression.name.stringify }},
          {{expression.stringify}},
          {{ expression }},
          %receiver, %args, %named_args
        )
      end

      getter method_name : String
      getter receiver : Node
      getter arguments : Array(Node)

      def initialize(@method_name : String, expression : String, value : T,
                     @receiver : Node, @arguments : Array(Node),
                     @named_arguments : Array(NamedArg)) forall T
        super(expression, value)
      end

      def operator?
        method_name.in?(OPERATORS)
      end

      def comparator?
        method_name.in?(%w(!= < <= <=> == === > >=))
      end

      def nested_expressions : Array(Evaluation)
        result = [] of Evaluation

        result += receiver.nested_expressions

        result += arguments.flat_map(&.nested_expressions)

        # result << Evaluation.new(expression, value)

        result
      end

      def_equals_and_hash method_name, expression, value, receiver, arguments, @named_arguments # , @block
    end

    class NamedArg < Node
      getter name : String

      # FIXME implement
      def initialize(@name, value)
        super("", value)
      end

      def nested_expressions : Array(Evaluation)
        [] of Evaluation
      end
    end

    class TerminalNode < Node
      def initialize(expression : String, value : T) forall T
        super(expression, value)
      end

      def nested_expressions : Array(Evaluation)
        if expression == value.inspect
          [] of Evaluation
        else
          [Evaluation.new(expression, value)] of Evaluation
        end
      end

      def_equals_and_hash expression, value
    end

    macro reflect(expression, nest = true)
      {% if expression.is_a?(Call) %}
        {% if Call::OPERATORS.includes?(expression.name) %}
          Microtest::PowerAssert::Call.build({{ expression.id }}, true)
        {% else %}
          Microtest::PowerAssert::Call.build({{ expression.id }}, true)
        {% end %}
      {% else %}
        Microtest::PowerAssert::TerminalNode.new({{expression.stringify}}, {{expression}})
      {% end %}
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
