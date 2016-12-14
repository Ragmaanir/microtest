macro describe(&block)
  class X < Test
    {{block.body}}
  end
end

module TestDSL
  macro test(name, &block)
    self.focused_tests << {{name}}

    def test__{{name.id}}
      {{block.body}}
    end
  end
end

class Test
  include TestDSL

  def self.focused_tests
    @@focused_tests ||= [] of String
  end

  macro def self.test_classes : Array(Test.class)
    {{ ("[" + @type.all_subclasses.join(", ") + "] of Test.class").id }}
  end

  macro def self.run_tests
    {% begin %}
      {% names = @type.methods.map(&.name).select(&.starts_with?("test__")) %}
      {% for n in names %}
        puts "{{n}}"
        new.{{n}}
      {% end %}
    {% end %}
  end
end

Test.test_classes.each do |c|
  c.run_tests
end
