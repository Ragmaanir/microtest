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

    macro pending(name = "anonymous", *args, **options, &block)
      test({{name}}, {{*(args + [:skip])}}, {{**options}}) {{block}}
    end

    macro test!(name = "anonymous", *args, **options, &block)
      test({{name}}, {{*(args + [:focus])}}, {{**options}}) {{block}}
    end

    macro test(name = "anonymous", *args, __filename = __FILE__, __line_number = __LINE__, **options, &block)
      {%
        sanitized_name = name.gsub(/[^a-zA-Z0-9_]/, "_")
        focus = args.includes?(:focus)
        # TODO pass custom skip message
        skip = args.includes?(:skip) || !block
      %}

      @[Microtest::TestMethod(
        name: {{name}},
        focus: {{focus}},
        skip: {{skip}},
        __filename: {{__filename}},
        __line_number: {{__line_number}}
      )]
      def test__{{sanitized_name.id}}
        {% if block %}
          {{block.body}}
        {% end %}
      end
    end
  end
end
