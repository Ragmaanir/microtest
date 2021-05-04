module Microtest
  def self.find_crystal_root_path
    # find the backtrace entry for crystals main method
    first_entry = caller.reverse.find { |l| %r{in 'main'} === l } || Microtest.bug("Could not determine crystal path from caller stacktrace")

    path = first_entry.split(":").first

    # move up from:
    #   "?/crystal-1.0.0/share/crystal/src/crystal/main.cr"
    # to:
    #   "?/crystal-1.0.0/share/crystal/src"
    File.expand_path(File.join(path, "..", ".."))
  end

  CRYSTAL_DIR      = find_crystal_root_path
  PROJECT_DIR      = Dir.current
  PROJECT_LIB_DIR  = File.join(PROJECT_DIR, "lib")
  PROJECT_SRC_DIR  = File.join(PROJECT_DIR, "src")
  PROJECT_SPEC_DIR = File.join(PROJECT_DIR, "spec")

  # e.g.: "spec/spec_helper.cr:64:1 in '__crystal_main'"
  STRACKTRACE_LINE_REGEX = /\A(.+):(\d+):(\d+) in \'(\S+)\'\z/

  class BacktracePrinter
    record(Entry, kind : Symbol, path : String, line : Int32, func : String)

    def self.classify_path(path : String) : Symbol
      case path
      when .starts_with?(PROJECT_LIB_DIR)  then :lib
      when .starts_with?(PROJECT_SRC_DIR)  then :app
      when .starts_with?(PROJECT_SPEC_DIR) then :spec
      when .starts_with?(CRYSTAL_DIR)      then :crystal
      when .starts_with?("/eval")          then :eval
      else                                      :unknown
      end
    end

    def self.simplify_path(path : String, raise_on_unmatched_file = false)
      kind = classify_path(path)

      simple_path = case kind
                    when :lib     then path.sub(PROJECT_LIB_DIR, "LIB: lib")
                    when :app     then path.sub(PROJECT_SRC_DIR, "APP: src")
                    when :spec    then path.sub(PROJECT_SPEC_DIR, "SPEC: spec")
                    when :crystal then path.sub(CRYSTAL_DIR, "CRY: ")
                    when :eval    then "EVAL: #{path}"
                    when :unknown
                      if raise_on_unmatched_file
                        Microtest.bug("Path in backtrace could not be classified: #{path}")
                      else
                        "???: #{path}"
                      end
                    else Microtest.bug("Case not implemented: #{kind} for #{path}")
                    end

      {kind, simple_path}
    end

    def call(backtrace : Array(String), colorize : Bool, raise_on_unmatched_file : Bool) : String
      entries = simplify(backtrace, raise_on_unmatched_file)

      list = entries.map do |entry|
        Termart.string(colorize) { |t|
          t.w(entry.path, fg: BACKTRACE_KIND_COLORS[entry.kind])

          t.w(":", entry.line.to_s, " ", fg: :dark_gray)

          case entry.kind
          when :app, :spec then t.w(entry.func, fg: :yellow)
          else                  t.w(entry.func, fg: :dark_gray)
          end
        }
      end

      Termart.string(colorize) { |t| t.grouped_lines(list, :dark_gray) }
    end

    BACKTRACE_KIND_COLORS = {
      :app     => :light_magenta,
      :spec    => :light_magenta,
      :eval    => :dark_gray,
      :crystal => :dark_gray,
      :lib     => :magenta,
      :unknown => :cyan,
    }

    def simplify(backtrace : Array(String), raise_on_unmatched_file : Bool) : Array(Entry)
      entries = [] of Entry

      backtrace.each do |l|
        if m = STRACKTRACE_LINE_REGEX.match(l)
          file = m[1]
          line = m[2].to_i
          # column = m[3]
          func = m[4]

          entries << Entry.new(
            *self.class.simplify_path(
              File.expand_path(file),
              raise_on_unmatched_file
            ),
            line,
            func
          )
        end
      end

      entries.reverse
    end
  end
end
