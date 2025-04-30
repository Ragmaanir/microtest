require "colorize"

module Microtest
  alias RGB = Colorize::ColorRGB

  GREEN         = RGB.new(0, 220, 0)
  RED           = RGB.new(220, 0, 0)
  YELLOW        = RGB.new(220, 220, 0)
  WHITE         = RGB.new(255, 255, 255)
  DARK_GRAY     = RGB.new(100, 100, 100)
  LIGHT_GRAY    = RGB.new(200, 200, 200)
  MAGENTA       = RGB.new(205, 0, 205)
  LIGHT_MAGENTA = RGB.new(220, 0, 220)
  CYAN          = RGB.new(0, 205, 205)
  LIGHT_BLUE    = RGB.new(90, 90, 250)

  class Termart
    def self.string(colorize : Bool, &) : String
      String.build do |io|
        t = new(io, colorize)
        yield t
      end
    end

    def self.io(io : IO, colorize : Bool, &)
      t = new(io, colorize)
      yield t
      nil
    end

    getter io : IO
    getter? colorize

    def initialize(@io, @colorize : Bool = true)
    end

    private def colorized_io(fg : RGB? = nil, bg : RGB? = nil, m : Colorize::Mode? = nil, &)
      if colorize?
        c = Colorize.with
        c = c.fore(fg) if fg
        c = c.mode(m) if m
        c = c.back(bg) if bg

        c.surround(io) do |cio|
          yield cio
        end
      else
        yield io
      end
    end

    def w(*strs : String | Int32 | Nil, fg : RGB? = nil, bg : RGB? = nil, m : Colorize::Mode? = nil)
      colorized_io(fg, bg, m) do |cio|
        strs.each { |s| cio << s }
      end
    end

    def l(*args, **opts)
      w(*args, **opts)
      br
    end

    def br
      w("\n")
    end

    def flush
      io.flush
    end

    def grouped_lines(lines : Array(String), bar_color : RGB? = nil)
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
