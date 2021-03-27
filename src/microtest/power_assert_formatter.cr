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
        if node.is_a?(Call)
          if node.comparator?
            call_compare(node)
          else
            call_only(node)
          end
        else
          literal(node)
        end
      end

      private def grouped_lines(lines : Array(String))
        String.build do |io|
          if lines.size == 1
            io << color("◆ ", BAR_COLOR)
            io << lines.shift
            io << "\n"
          else
            io << color("┏ ", BAR_COLOR)
            io << lines.shift
            io << "\n"

            while lines.size > 1
              io << color("┃ ", BAR_COLOR)
              io << lines.shift
              io << "\n"
            end

            io << color("┗ ", BAR_COLOR)
            io << lines.shift
            io << "\n"
          end
        end
      end

      private def literal(node : TerminalNode)
        v = node.value.value
        simpler_exp = if v.is_a?(Array) && v.size > 1
                        "[#{v[0].inspect}, ...]"
                      else
                        v.inspect
                      end

        simplified = simpler_exp != node.expression
        is_complex_result = ![true, false].includes?(v)
        nest = simplified && is_complex_result

        lines = [
          "#{color("assert", :red)} #{color(node.expression, :red, :bold)}",
        ]

        lines << simpler_exp if nest

        grouped_lines(lines)
      end

      #
      # When: [1].empty?
      # => [1].empty?
      # When: ![1].empty?
      # =>
      # When: !result.empty?
      # => [elem1, ...].empty?
      # When: result.contains?(1.minute)
      # => [elem1, ...].contains?(00:01:00)
      # When: nonzero?(55 * 3 + Math.sin(angle))
      # => nonzero?(160)
      private def call_only(node : Call)
        rv = node.receiver.value.value
        rstr = if rv.is_a?(Array) && rv.size > 1
                 "[#{rv[0].inspect}, ...]"
               else
                 rv.inspect
               end

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
            s << node.arguments.join(", ") { |a| a.value.value.inspect }
            s << ")" if !node.operator?
          end
        end

        simplified = simpler_exp != node.expression
        is_complex_result = node.value.value != false

        lines = [] of String

        lines << "#{color("assert", :red)} #{color(node.expression, :red, :bold)}"

        lines << simpler_exp if simplified

        lines << node.value.value.inspect if is_complex_result

        grouped_lines(lines)
      end

      # e.g.: a == b, c > d
      #
      # When inspect-strings longer than N characters, then display compared values
      # in two lines. Otherwise display them in the same line.
      private def call_compare(node : Call)
        left, right = node.receiver, node.arguments[0]

        lval = left.value.value.inspect
        rval = right.value.value.inspect

        simpler_exp = String.build do |s|
          s << lval

          s << " "
          s << node.method_name
          s << " "

          s << rval
        end

        simplified = simpler_exp != node.expression

        lines = [] of String

        lines << "#{color("assert", :red)} #{color(node.expression, :red, :bold)}"

        if simplified
          # if the inspects of left and right dont fit in one line,
          # display the in two lines.
          multi_line = lval.size + rval.size > 20

          if multi_line
            # FIXME: indicate that these two lines are not simplifications, but different values
            # e.g. by highlighting the first character difference
            lines << lval
            lines << rval
          else
            lines << "#{lval} #{color(node.method_name, :dark_gray)} #{rval}"
          end
        end

        grouped_lines(lines)
      end

      private def color(s : String, c : Symbol, m : Symbol? = nil)
        return s if !colorize?
        s = s.colorize(c)
        s = s.mode(m) if m
        s
      end

      # def call(node : Node) : String
      #   # FIXME too much complex code, refactor into two methods, compact and complex or so
      #   expressions = node.nested_expressions.uniq
      #   complete_expression = expressions.empty? ? node : expressions.last

      #   sizes = expressions.map do |ev|
      #     {left: ev.expression.size, right: ev.value.inspect.size}
      #   end

      #   max_sizes = sizes.reduce({left: 0, right: 0}) do |max, s|
      #     {
      #       left:  [max[:left], s[:left]].max,
      #       right: [max[:right], s[:right]].max,
      #     }
      #   end

      #   big_bar = "=" * 50
      #   small_bar = "-" * 50

      #   is_compact = max_sizes[:left] < 32 && max_sizes[:right] < 50

      #   exp_width = [8, 12, 16, 20, 24].find { |limit| max_sizes[:left] < limit } || 24

      #   assert_line = [
      #     "⚑ assert ".colorize(:red),
      #     complete_expression.expression.to_s.colorize(:yellow),
      #     " # ".colorize(:dark_gray),
      #     complete_expression.value.inspect.colorize(:dark_gray),
      #   ].join

      #   expression_values = expressions[0..-2].join("\n") do |ev|
      #     val = ev.value.inspect
      #     exp_str = if is_compact
      #                 "%-#{exp_width}s" % ev.expression
      #               else
      #                 ev.expression.to_s
      #               end

      #     [
      #       exp_str.colorize.fore(:yellow),
      #       (is_compact ? " => " : "\n").colorize(:light_blue),
      #       val,
      #       ("\n" + small_bar.colorize(:light_blue).to_s if !is_compact),
      #     ].join.colorize(:white)
      #   end

      #   [
      #     assert_line,
      #     if expressions.size > 1
      #       [
      #         big_bar.colorize(:light_blue),
      #         expression_values,
      #       ].join("\n")
      #     end,
      #   ].join("\n")
      # end
    end
  end
end
