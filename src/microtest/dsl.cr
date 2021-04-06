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

    macro pending(name = nil, *args, __filename = __FILE__, __line_number = __LINE__, **options, &block)
      test({{name}}, {{*(args + [:skip])}}, {{**options}}) {{block}}
    end

    macro test!(name = nil, *args, __filename = __FILE__, __line_number = __LINE__, **options, &block)
      test({{name}}, {{*(args + [:focus])}}, {{**options}}) {{block}}
    end

    macro test(name = nil, *args, __filename = __FILE__, __line_number = __LINE__, **options, &block)
      {%
        raise "Test name cant be empty" if name == ""

        name = "unnamed_in_line_#{__line_number}" if name == nil

        sanitized_name = name.gsub(/[^a-zA-Z0-9_]/, "_")
        method_name = "test__#{sanitized_name.id}"

        if @type.has_method?(method_name)
          raise "Test method with same name already defined: #{method_name.id} (#{name})"
        end

        focus = args.includes?(:focus)
        # TODO pass custom skip message
        skip = args.includes?(:skip) || !block
      %}

      def self.test_methods
        # collect all test methods using the previous_def-hack
        previous_def + [
          Microtest::TestMethod.new(
            name: {{name}},
            focus: {{focus}},
            skip: {{skip}},
            # __filename: {{__filename}},
            # __line_number: {{__line_number}},
          ) do |m, ctx|
            test = new(ctx)
            test.run_test(m) { test.{{ method_name.id }} }
          end
        ]
      end

      def {{method_name.id}}
        {% if block && !skip %}
          {{block.body}}
        {% else %}
          skip("not implemented")
        {% end %}
      end
    end
  end
end
