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
    record(Entry, original : String, file : String, line : Int32, func : String) do
      def pretty_path(colorize : Bool, raise_on_unmatched_file : Bool)
        Termart.string(colorize) { |t|
          case file
          when %r{\Alib/}  then t.w("LIB: #{file}", fg: :magenta)
          when %r{\Asrc/}  then t.w("APP: #{file}", fg: :light_magenta)
          when %r{\Aspec/} then t.w("SPEC: #{file}", fg: :light_magenta)
          else
            case exp = File.expand_path(file)
            when %r{\A/eval}                then t.w("EVAL: #{exp}", fg: :dark_gray)
            when .starts_with?(CRYSTAL_DIR) then t.w(exp.sub(CRYSTAL_DIR, "CRY: "), fg: :dark_gray)
            else
              if raise_on_unmatched_file
                raise "Path in backtrace could not be classified: #{file}"
              else
                t.w("???: #{original}", fg: :cyan)
              end
            end
          end
        }
      end
    end

    def call(backtrace : Array(String), colorize = true, raise_on_unmatched_file = false)
      entries = simplify(backtrace)

      Termart.string(colorize) { |t|
        entries.each do |entry|
          t.w(entry.pretty_path(colorize, raise_on_unmatched_file))
          t.w(":", entry.line.to_s, " ", fg: :dark_gray)
          t.w(entry.func, fg: :yellow)
          t.br
        end
      }
    end

    def simplify(backtrace : Array(String)) : Array(Entry)
      entries = [] of Entry

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
