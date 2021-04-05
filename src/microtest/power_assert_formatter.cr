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

        lines = [
          "#{color("assert", :red)} #{color(node.expression, :red, :bold)}",
        ]

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

        lines << "#{color("assert", :red)} #{color(node.expression, :red, :bold)}"

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

        lines << "#{color("assert", :red)} #{color(node.expression, :red, :bold)}"

        if simpler_exp != node.expression
          # if the inspects of left and right dont fit in one line,
          # display them in two lines.
          if lval.size + rval.size > 20
            # FIXME: indicate that these two lines are not simplifications,
            # but different values.

            diff_idx = string_diff_index(lval, rval) || raise "BUG: Strings are not different"

            lines << highlight_split_char(split_string_at(lval, diff_idx))
            lines << highlight_split_char(split_string_at(rval, diff_idx))
          else
            lines << "#{lval} #{color(node.method_name, :dark_gray)} #{rval}"
          end
        end

        grouped_lines(lines)
      end

      private def string_diff_index(left : String, right : String) : Int32?
        left.chars.zip?(right.chars).index { |(l, r)| l != r }
      end

      private def split_string_at(str : String, i : Int32) : Tuple(String, String, String)
        {
          str[0..(i - 1)],
          str[i, 1],
          str[(i + 1)..-1],
        }
      end

      private def highlight_split_char(t : Tuple(String, String, String)) : String
        "#{t[0]}#{color(t[1], :white, bg: :red)}#{t[2]}"
      end

      private def color(s : String, fg : Symbol, m : Symbol? = nil, bg : Symbol? = nil)
        return s if !colorize?
        s = s.colorize(fg)
        s = s.mode(m) if m
        s = s.back(bg) if bg
        s
      end
    end
  end
end
