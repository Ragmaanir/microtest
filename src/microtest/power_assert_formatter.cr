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

      def initialize(@colorize : Bool = true)
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

      private def build_string : String
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
        v = n.wrapper.value
        if v.is_a?(Array) && v.size > 1
          String.build do |io|
            s = 0
            io << "["
            io << v.map(&.inspect).take_while { |str|
              s += str.size + 2
              s < max_length
            }.join(", ")
            io << "]"
          end
        else
          n.wrapper.inspect
        end
      end

      private def literal(node : TerminalNode) : String
        v = node.wrapper.value
        simpler_exp = simplify_value(node)

        simplified = simpler_exp != node.expression
        is_complex_result = ![true, false].includes?(v)
        nest = simplified && is_complex_result

        lines = [] of String

        lines << formatted_assert_statement(node)

        lines << simpler_exp if nest

        grouped_lines(lines)
      end

      private def call_only(node : CallNode) : String
        rv = node.receiver.wrapper.value
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
            s << node.arguments.join(", ", &.wrapper.inspect)
            s << ")" if !node.operator?
          end
        end

        lines = [] of String

        lines << formatted_assert_statement(node)

        lines << simpler_exp if simpler_exp != node.expression

        lines << node.wrapper.inspect if node.wrapper.value != false

        grouped_lines(lines)
      end

      # When inspect-strings longer than N characters, then display compared values
      # in two lines. Otherwise display them in the same line.
      private def call_compare(node : CallNode) : String
        left, right = node.receiver, node.arguments[0]

        lval = left.wrapper.inspect
        rval = right.wrapper.inspect

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
