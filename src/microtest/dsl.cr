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
      test({{name}}, {{(args + [:skip]).splat}}, {{options.double_splat}}) {{block}}
    end

    macro test!(name = nil, *args, __filename = __FILE__, __line_number = __LINE__, **options, &block)
      test({{name}}, {{(args + [:focus]).splat}}, {{options.double_splat}}) {{block}}
    end

    macro test(name = nil, *args, __filename = __FILE__, __line_number = __LINE__, **options, &block)
      {%
        file = __filename
        line = __line_number

        if block
          file = block.filename
          line = block.line_number
        end

        raise "Test name cant be empty in #{file}:#{line}" if name == ""

        name = "unnamed_in_line_#{line}" if name == nil

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
            suite: self,
            name: {{name}},
            sanitized_name: {{sanitized_name}},
            method_name: {{method_name}},
            focus: {{focus}},
            skip: {{skip}},
            filename: {{file}},
            line_number: {{line}},
          ) do |m, ctx|
            test = new(ctx)
            test.run_test(m) { test.{{ method_name.id }} }
          end
        ]
      end

      def {{method_name.id}} : Nil
        {% if skip %}
          skip("not implemented")
        {% end %}
        {% if block %}
          {{block.body}}
        {% end %}
        nil
      end
    end
  end
end
