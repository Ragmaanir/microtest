require "./string_utils"

module Microtest
  module PowerAssert
    abstract class Formatter
      abstract def call(node : Node) : String
    end

    class ListFormatter < Formatter
      BAR_COLOR        = RGB.new(200, 50, 50)
      ASSERT_COLOR     = RGB.new(200, 0, 0)
      ASSERT_EXP_COLOR = RGB.new(250, 80, 80)

      getter? colorize

      def initialize(@colorize : Bool = Termart.color_default?)
      end

      def call(node : Node) : String
        if node.is_a?(CallNode)
          if node.comparator?
            call_compare(node)
          else
            call_only(node)
          end
        else
          literal(node)
        end
      end

      private def build_string(&) : String
        Termart.string(colorize?) { |t| yield t }
      end

      private def grouped_lines(lines : Array(String)) : String
        build_string(&.grouped_lines(lines, BAR_COLOR))
      end

      # Returns colorized "assert x == y"
      private def formatted_assert_statement(node : CallNode | TerminalNode) : String
        build_string { |t|
          t.w("assert", fg: ASSERT_COLOR)
          t.w(" ")
          t.w(node.expression, fg: ASSERT_EXP_COLOR, m: :bold)
        }
      end

      private def simplify_value(n : Node, max_length = 64) : String
        n.wrapper.simplified_value(max_length)
      end

      # Inspect each concrete value through a fixed return type.
      private def inspected(wrapper : Value) : String
        wrapper.inspected
      end

      private def literal(node : TerminalNode) : String
        simpler_exp = simplify_value(node)

        simplified = simpler_exp != node.expression
        is_complex_result = !node.wrapper.boolean?
        nest = simplified && is_complex_result

        lines = [] of String

        lines << formatted_assert_statement(node)

        lines << simpler_exp if nest

        grouped_lines(lines)
      end

      private def call_only(node : CallNode) : String
        rv = node.receiver.wrapper.truthy?
        rstr = simplify_value(node.receiver)

        simpler_exp = String.build do |s|
          if rv
            s << rstr
          end

          if node.operator?
            s << " "
            s << node.method_name
            s << " "
          else
            s << "." if rv
            s << node.method_name
          end

          if !node.arguments.empty?
            s << "(" if !node.operator?
            s << node.arguments.join(", ") { |arg| inspected(arg.wrapper) }
            s << ")" if !node.operator?
          end
        end

        lines = [] of String

        lines << formatted_assert_statement(node)

        lines << simpler_exp if simpler_exp != node.expression

        lines << inspected(node.wrapper) if node.wrapper.not_false?

        grouped_lines(lines)
      end

      # When inspect-strings longer than N characters, then display compared values
      # in two lines. Otherwise display them in the same line.
      private def call_compare(node : CallNode) : String
        left, right = node.receiver, node.arguments[0]

        lval = inspected(left.wrapper)
        rval = inspected(right.wrapper)

        simpler_exp = String.build do |s|
          s << lval

          s << " "
          s << node.method_name
          s << " "

          s << rval
        end

        lines = [] of String

        lines << formatted_assert_statement(node)

        if simpler_exp != node.expression
          # if the inspects of left and right dont fit in one line,
          # display them in two lines.
          if lval.size + rval.size > 20
            # FIXME: indicate that these two lines are not simplifications,
            # but different values.

            if diff_idx = StringUtils.diff_index(lval, rval)
              lines << highlight_split_char(lval, diff_idx)
              lines << highlight_split_char(rval, diff_idx)
            else
              lines << "inspect returned the same result for both values: #{lval}"
            end
          else
            lines << build_string { |t|
              t.w(lval)
              t.w(" ", node.method_name, " ", fg: DARK_GRAY)
              t.w(rval)
            }
          end
        end

        grouped_lines(lines)
      end

      private def highlight_split_char(str : String, at : Int32) : String
        parts = StringUtils.split_at(str, at)

        build_string { |a|
          a.w(parts[0])
          a.w(parts[1], fg: WHITE, bg: RED)
          a.w(parts[2])
        }
      end
    end
  end
end
