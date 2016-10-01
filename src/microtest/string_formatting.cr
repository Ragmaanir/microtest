module Microtest
  module StringFormatting
    def format_large_number(number, separator : String = ",")
      number.to_s.reverse.gsub(/(\d{3})(?=.)/, "\\1#{separator}").reverse
    end

    macro format_string(str)
      {%
        color = str[0] || :white
        output = [] of String
      %}
      {% for e, i in str %}
        {% if i > 0 %}
          {% if e.is_a?(TupleLiteral) %}
            {% output << "format_string(#{e})" %}
          {% else %}
            {% output << "#{e}" %}
          {% end %}
        {% end %}
      {% end %}

      {% output = output.join(",") %}

      {% res = "[" + output + "]" + ".join.colorize(#{color})" %}

      {{res.id}}
    end
  end
end
