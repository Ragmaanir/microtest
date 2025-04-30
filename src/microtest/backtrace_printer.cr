module Microtest
  def self.find_crystal_root_path : String
    # find the backtrace entry for crystals main method
    first_entry = caller.reverse.find { |l| %r{in 'main'} === l } || Microtest.bug("Could not determine crystal path from caller backtrace")

    raw_path = Path.new(first_entry.split(":").first)

    parts = raw_path.parts

    # Move up from /???/crystal-1.16.0-1/share/crystal/src/crystal/system/unix/main.cr
    while parts.last != "src"
      parts.pop
    end

    Path.new(parts).to_s
  end

  CRYSTAL_DIR      = find_crystal_root_path
  PROJECT_DIR      = Dir.current
  PROJECT_LIB_DIR  = File.join(PROJECT_DIR, "lib")
  PROJECT_SRC_DIR  = File.join(PROJECT_DIR, "src")
  PROJECT_SPEC_DIR = File.join(PROJECT_DIR, "spec")

  # e.g.: "spec/spec_helper.cr:64:1 in '__crystal_main'"
  BACKTRACE_LINE_REGEX = /\A(.+):(\d+):(\d+) in \'(\S+)\'\z/

  class BacktracePrinter
    record(Entry, kind : Symbol, path : String, line : Int32, func : String)

    def self.classify_path(path : String) : Symbol
      case path
      when .starts_with?(PROJECT_LIB_DIR)  then :lib
      when .starts_with?(PROJECT_SRC_DIR)  then :app
      when .starts_with?(PROJECT_SPEC_DIR) then :spec
      when .starts_with?(CRYSTAL_DIR)      then :crystal
      when .starts_with?("eval")           then :eval
      else                                      :unknown
      end
    end

    def self.simplify_path(path : String)
      kind = classify_path(path)

      simple_path = case kind
                    when :lib     then path.sub(PROJECT_LIB_DIR, "LIB: lib")
                    when :app     then path.sub(PROJECT_SRC_DIR, "APP: src")
                    when :spec    then path.sub(PROJECT_SPEC_DIR, "SPEC: spec")
                    when :crystal then path.sub(CRYSTAL_DIR, "CRY: ")
                    when :eval    then "EVAL: #{path}"
                    when :unknown
                      {% if env("BACKTRACE_ERRORS") %}
                        Microtest.bug("Path in backtrace could not be classified: #{path}")
                      {% else %}
                        "???: #{path}"
                      {% end %}
                    else Microtest.bug("Case not implemented: #{kind} for #{path}")
                    end

      {kind, simple_path}
    end

    def call(backtrace : Array(String), highlight : String? = nil, colorize : Bool = true) : String
      entries = simplify(backtrace)

      list = entries.map do |entry|
        Termart.string(colorize) { |t|
          t.w(entry.path, fg: BACKTRACE_KIND_COLORS[entry.kind])

          t.w(":", entry.line.to_s, " ", fg: DARK_GRAY)

          m = Colorize::Mode::None
          m = Colorize::Mode::Bold if highlight && entry.func.includes?(highlight)

          case entry.kind
          when :app, :spec then t.w(entry.func, fg: YELLOW, m: m)
          else                  t.w(entry.func, fg: DARK_GRAY, m: m)
          end
        }
      end

      Termart.string(colorize) { |t| t.grouped_lines(list, DARK_GRAY) }
    end

    BACKTRACE_KIND_COLORS = {
      :app     => LIGHT_MAGENTA,
      :spec    => LIGHT_MAGENTA,
      :eval    => DARK_GRAY,
      :crystal => DARK_GRAY,
      :lib     => MAGENTA,
      :unknown => CYAN,
    }

    def simplify(backtrace : Array(String)) : Array(Entry)
      entries = [] of Entry

      backtrace.each do |l|
        if m = BACKTRACE_LINE_REGEX.match(l)
          file = m[1]
          line = m[2].to_i
          # column = m[3]
          func = m[4]

          entries << Entry.new(
            *self.class.simplify_path(File.expand_path(file)),
            line,
            func
          )
        end
      end

      entries.reverse
    end
  end
end
