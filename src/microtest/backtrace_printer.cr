module Microtest
  macro compile_time_command(cmd)
    "{{system(cmd)}}".strip
  end

  CRYSTAL_DIR      = compile_time_command("readlink -f `which crystal`").sub("/embedded/bin/crystal", "")
  APP_COMPILE_ROOT = compile_time_command("readlink -f `pwd`")
  LIB_COMPILE_ROOT = compile_time_command("readlink -f `pwd`") + "/lib"

  class BacktracePrinter
    def call(backtrace : Array(String))
      stack = Array(Array(String)).new

      backtrace.each do |line|
        if m = /\A(\dx[a-z0-9]+): (.+) at (\S+) (\d+):(\d+)\z/.match(line)
          addr = m[1]
          func = m[2]
          path = m[3]
          line_no = m[4]

          stack << [line, "%4s" % line_no, path, func, addr]
        end
      end

      strs = stack.map do |line|
        line_2 = case l = line[2]
                 when Regex.new(CRYSTAL_DIR)
                   l.sub(CRYSTAL_DIR, "CRY: ").colorize(:dark_gray)
                 when Regex.new(LIB_COMPILE_ROOT)
                   l.sub(LIB_COMPILE_ROOT, "LIB: ").colorize(:magenta)
                 when Regex.new(APP_COMPILE_ROOT)
                   l.sub(APP_COMPILE_ROOT, "APP: ").colorize(:light_magenta)
                 end
        [
          line[1].colorize(:light_gray),
          line_2,
          line[3].colorize(:yellow),
        ].join(" ")
      end.reverse

      puts strs.join("\n")
    end
  end
end
