module Microtest
  module StringUtils
    # return the index of the first different character
    def self.diff_index(left : String, right : String) : Int32?
      left.chars.zip?(right.chars).index { |(l, r)| l != r }
    end

    # split the string into three parts: before, at, and after the passed index
    def self.split_at(str : String, i : Int32) : Tuple(String, String, String)
      after_idx = (i + 1)
      {
        str[0, i],
        str[i, 1],
        after_idx < str.size ? str[after_idx..-1] : "",
      }
    end
  end
end
