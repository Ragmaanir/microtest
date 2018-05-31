module Microtest
  {% if flag?(:darwin) %}
    CRYSTAL_EXECUTABLE = {{system("readlink `which crystal`").stringify}}
  {% else %}
    CRYSTAL_EXECUTABLE = {{system("readlink -f `which crystal`").stringify}}
  {% end %}

  CRYSTAL_DIR = CRYSTAL_EXECUTABLE.strip.sub("/embedded/bin/crystal", "")

  STRACKTRACE_LINE_REGEX = /\A(.+):(\d+):(\d+) in \'(\S+)\'\z/

  class BacktracePrinter
    record Entry, file : String, line : Int32, func : String

    def call(backtrace : Array(String))
      entries = simplify(backtrace)

      strs = entries.map do |entry|
        path = case name = entry.file
               when Regex.new(CRYSTAL_DIR)
                 name.sub(CRYSTAL_DIR, "CRY: ").colorize(:dark_gray)
               when .starts_with?("lib/")
                 "LIB: #{name}".colorize(:magenta)
               when .starts_with?("src")
                 "APP: #{name}".colorize(:light_magenta)
               when .starts_with?("spec")
                 "SPEC: #{name}".colorize(:light_magenta)
               else
                 puts "Could not handle backtrace for #{name.inspect}, please report".colorize(:cyan)
                 name
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

      backtrace.each do |line|
        if m = STRACKTRACE_LINE_REGEX.match(line)
          file = m[1]
          line = m[2].to_i
          column = m[3]
          func = m[4]

          entries << Entry.new(file, line, func)
        end
      end

      entries.reverse
    end
  end
end
