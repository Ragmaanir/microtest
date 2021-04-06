module Microtest
  def self.find_crystal_root_path
    # find the backtrace entry for crystals main method
    first_entry = caller.reverse.find { |l| %r{in 'main'} === l } || raise("Could not determine crystal path from caller stacktrace")

    path = first_entry.split(":").first

    # move up from:
    #   "?/crystal-1.0.0/share/crystal/src/crystal/main.cr"
    # to:
    #   "?/crystal-1.0.0/share/crystal/src"
    File.expand_path(File.join(path, "..", ".."))
  end

  CRYSTAL_DIR = find_crystal_root_path

  # e.g.: "spec/spec_helper.cr:64:1 in '__crystal_main'"
  STRACKTRACE_LINE_REGEX = /\A(.+):(\d+):(\d+) in \'(\S+)\'\z/

  class BacktracePrinter
    record(Entry, kind : Symbol, path : String, line : Int32, func : String)

    def self.simplify_path(path : String, raise_on_unmatched_file = false)
      exp = File.expand_path(path)

      kind = case path
             when %r{\Alib/}  then :lib
             when %r{\Asrc/}  then :app
             when %r{\Aspec/} then :spec
             else
               case exp
               when %r{\A/eval}                then :eval
               when .starts_with?(CRYSTAL_DIR) then :crystal
               else                                 :unknown
               end
             end

      simple_path = case kind
                    when :lib     then "LIB: #{path}"
                    when :app     then "APP: #{path}"
                    when :spec    then "SPEC: #{path}"
                    when :eval    then "EVAL: #{exp}"
                    when :crystal then exp.sub(CRYSTAL_DIR, "CRY: ")
                    when :unknown
                      if raise_on_unmatched_file
                        raise "Path in backtrace could not be classified: #{path}"
                      else
                        "???: #{path}"
                      end
                    else Microtest.bug("Case not implemented: #{kind}")
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

          entries << Entry.new(*self.class.simplify_path(file, raise_on_unmatched_file), line, func)
        end
      end

      entries.reverse
    end
  end
end
