require "./string_utils"

module Microtest
  module PowerAssert
    abstract class Formatter
      abstract def call(node : Node) : String
    end

    class ListFormatter < Formatter
      BAR_COLOR = :light_red

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

      private def grouped_lines(lines : Array(String), bar_color = BAR_COLOR) : String
        Termart.string(colorize?) { |t| t.grouped_lines(lines) }
      end

      # Returns colorized "assert x == y"
      private def formatted_assert_statement(node : CallNode | TerminalNode) : String
        Termart.string(colorize?) { |t|
          t.w("assert", fg: :red)
          t.w(" ")
          t.w(node.expression, fg: :red, m: :bold)
        }
      end

      private def simplify_value(v : V, max_length = 64) forall V
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
          v.inspect
        end
      end

      private def literal(node : TerminalNode)
        v = node.value
        simpler_exp = simplify_value(v)

        simplified = simpler_exp != node.expression
        is_complex_result = ![true, false].includes?(v)
        nest = simplified && is_complex_result

        lines = [] of String

        lines << formatted_assert_statement(node)

        lines << simpler_exp if nest

        grouped_lines(lines)
      end

      private def call_only(node : CallNode)
        rv = node.receiver.value
        rstr = simplify_value(rv)

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
            s << node.arguments.join(", ") { |a| a.value.inspect }
            s << ")" if !node.operator?
          end
        end

        lines = [] of String

        lines << formatted_assert_statement(node)

        lines << simpler_exp if simpler_exp != node.expression

        lines << node.value.inspect if node.value != false

        grouped_lines(lines)
      end

      # When inspect-strings longer than N characters, then display compared values
      # in two lines. Otherwise display them in the same line.
      private def call_compare(node : CallNode)
        left, right = node.receiver, node.arguments[0]

        lval = left.value.inspect
        rval = right.value.inspect

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

            diff_idx = StringUtils.diff_index(lval, rval) || raise "BUG: Strings are not different"

            lines << highlight_split_char(StringUtils.split_at(lval, diff_idx))
            lines << highlight_split_char(StringUtils.split_at(rval, diff_idx))
          else
            lines << Termart.string(colorize?) { |t|
              t.w(lval)
              t.w(" ", node.method_name, " ", fg: :dark_gray)
              t.w(rval)
            }
          end
        end

        grouped_lines(lines)
      end

      private def highlight_split_char(t : Tuple(String, String, String)) : String
        Termart.string(colorize?) { |a|
          a.w(t[0])
          a.w(t[1], fg: :white, bg: :red)
          a.w(t[2])
        }
      end
    end
  end
end
