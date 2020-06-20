module Microtest
  CRYSTAL_DIR = File.expand_path({{Crystal::PATH.split(":").last}})

  STRACKTRACE_LINE_REGEX = /\A(.+):(\d+):(\d+) in \'(\S+)\'\z/

  class BacktracePrinter
    record Entry, original : String, file : String, line : Int32, func : String

    def call(backtrace : Array(String), raise_on_unmatched_file = false)
      entries = simplify(backtrace)

      strs = entries.map do |entry|
        path = case name = entry.file
               when .starts_with?("lib/")
                 "LIB: #{name}".colorize(:magenta)
               when .starts_with?("src")
                 "APP: #{name}".colorize(:light_magenta)
               when .starts_with?("spec")
                 "SPEC: #{name}".colorize(:light_magenta)
               else
                 expanded = File.expand_path(name)
                 case expanded
                 when .starts_with?("/eval")
                   "EVAL: #{expanded}".colorize(:dark_gray)
                 when .starts_with?(CRYSTAL_DIR)
                   expanded.sub(CRYSTAL_DIR, "CRY: ").colorize(:dark_gray)
                 else
                   raise "Path in backtrace could not be classified: #{name}" if raise_on_unmatched_file
                   "???: #{entry.original}".colorize(:cyan)
                 end
               end
        [
          [
            path,
            ":".colorize(:dark_gray),
            entry.line.colorize(:dark_gray),
          ].join,
          entry.func.colorize(:yellow),
        ].join(" ")
      end

      strs.join("\n")
    end

    def simplify(backtrace : Array(String)) : Array(Entry)
      entries = Array(Entry).new

      backtrace.each do |l|
        if m = STRACKTRACE_LINE_REGEX.match(l)
          file = m[1]
          line = m[2].to_i
          # column = m[3]
          func = m[4]

          entries << Entry.new(l, file, line, func)
        end
      end

      entries.reverse
    end
  end
end
