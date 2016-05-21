module Microtest
  module StringFormatting

    def format_large_number(number, separator : String = ",")
      number.to_s.reverse.gsub(/(\d{3})/,"\\1#{separator}").reverse
    end

    def format_string(str)
      color = str[0] || :white
      (1..(str.size-1)).map do |i|
        item = str[i]
        case item
          when Tuple then format_string(item)
          else item.to_s
        end
      end.join.colorize(color)
    end

  end
end
