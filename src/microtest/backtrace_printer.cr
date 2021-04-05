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
    struct Entry
      getter file : String
      getter line : Int32
      getter func : String
      getter kind : Symbol

      def initialize(@file, @line, @func)
        @kind = Entry.path_kind(file)
      end

      def self.path_kind(path)
        case path
        when %r{\Alib/}  then :lib
        when %r{\Asrc/}  then :app
        when %r{\Aspec/} then :spec
        else
          case exp = File.expand_path(path)
          when %r{\A/eval}                then :eval
          when .starts_with?(CRYSTAL_DIR) then :crystal
          else                                 :unknown
          end
        end
      end

      def pretty_path(colorize : Bool, raise_on_unmatched_file : Bool)
        exp = File.expand_path(file)

        Termart.string(colorize) { |t|
          case kind
          when :lib     then t.w("LIB: #{file}", fg: :magenta)
          when :app     then t.w("APP: #{file}", fg: :light_magenta)
          when :spec    then t.w("SPEC: #{file}", fg: :light_magenta)
          when :eval    then t.w("EVAL: #{exp}", fg: :dark_gray)
          when :crystal then t.w(exp.sub(CRYSTAL_DIR, "CRY: "), fg: :dark_gray)
          when :unknown
            if raise_on_unmatched_file
              raise "Path in backtrace could not be classified: #{file}"
            else
              t.w("???: #{file}", fg: :cyan)
            end
          end
        }
      end
    end

    def call(backtrace : Array(String), colorize = true, raise_on_unmatched_file = false) : String
      entries = simplify(backtrace)

      list = format_lines(backtrace, colorize, raise_on_unmatched_file)

      Termart.string(colorize) { |t| t.grouped_lines(list, :dark_gray) }
    end

    def format_lines(backtrace : Array(String), colorize = true, raise_on_unmatched_file = false) : Array(String)
      entries = simplify(backtrace)

      entries.map do |entry|
        Termart.string(colorize) { |t|
          t.w(entry.pretty_path(colorize, raise_on_unmatched_file))
          t.w(":", entry.line.to_s, " ", fg: :dark_gray)
          if entry.kind.in?([:app, :spec])
            t.w(entry.func, fg: :yellow)
          else
            t.w(entry.func, fg: :dark_gray)
          end
        }
      end
    end

    def simplify(backtrace : Array(String)) : Array(Entry)
      entries = [] of Entry

      backtrace.each do |l|
        if m = STRACKTRACE_LINE_REGEX.match(l)
          file = m[1]
          line = m[2].to_i
          # column = m[3]
          func = m[4]

          entries << Entry.new(file, line, func)
        end
      end

      entries.reverse
    end
  end
end
