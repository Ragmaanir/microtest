module Microtest
  module TestClassDSL
    macro around(&block)
      def around_hooks(&block)
        super do
          {{block.body}}
        end
      end
    end

    macro before(&block)
      def before_hooks
        super
        {{block.body}}
      end
    end

    macro after(&block)
      def after_hooks
        {{block.body}}
        super
      end
    end

    macro pending(name = "anonymous", &block)
      {%
        testname = name.gsub(/\s+|-/, "_").id
      %}

      def __test__{{testname}}
        skip "pending"
      end
    end

    macro test!(name = "anonymous", &block)
      test({{name}}, :focus) {{block}}
    end

    macro test(name = "anonymous", focus = :nofocus, &block)
      {%
        testname = name.gsub(/\s+|-/, "_").id
        focus_str = focus == :focus ? "f" : ""
      %}

      def __test{{focus_str.id}}__{{testname}}
        {% if block %}
          {{block.body}}
        {% else %}
          skip "not implemented"
        {% end %}
      end
    end
  end
end
