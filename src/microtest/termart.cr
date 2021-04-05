require "colorize"

module Microtest
  class Termart
    def self.string(colorize : Bool) : String
      String.build do |io|
        t = new(io, colorize)
        yield t
      end
    end

    getter io : IO
    getter? colorize

    def initialize(@io, @colorize : Bool = true)
    end

    private def colorized_io(fg : Symbol? = nil, bg : Symbol? = nil, m : Symbol? = nil)
      if colorize?
        c = Colorize.with
        c = c.fore(fg) if fg
        c = c.mode(m) if m
        c = c.back(bg) if bg

        c.surround(io) do |c|
          yield c
        end
      else
        yield io
      end
    end

    def w(*strs : String, fg : Symbol? = nil, bg : Symbol? = nil, m : Symbol? = nil)
      colorized_io(fg, bg, m) do |cio|
        strs.each { |s| cio << s }
      end
    end

    def br
      w("\n")
    end

    def grouped_lines(lines : Array(String), bar_color : Symbol? = nil)
      if lines.size == 1
        w("◆", fg: bar_color)
        w(" ", lines.shift, "\n")
      else
        w("┏", fg: bar_color)
        w(" ", lines.shift, "\n")

        while lines.size > 1
          w("┃", fg: bar_color)
          w(" ", lines.shift, "\n")
        end

        w("┗", fg: bar_color)
        w(" ", lines.shift, "\n")
      end
    end
  end
end
