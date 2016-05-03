module Microtest

  module TestClassDSL

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

    macro test(name="anonymous", focus=:nofocus, &block)
      def test__{{name.gsub(/\s+/,"_").id}}
        {{block.body}}
      end
    end

  end

  class Test
    include TestClassDSL

    getter context : ExecutionContext

    def initialize(@context)
    end

    macro def self.test_classes : Array(Test.class)
      [{{ @type.all_subclasses.join(", ").id }}] of Test.class
    end

    macro def self.test_methods : Array(String)
      {% names = @type.methods.map(&.name).select(&.starts_with?("test__")) %}
      {% if names.empty? %}
        [] of String
      {% else %}
        [{{*names.map(&.stringify)}}]
      {% end %}
    end

    macro def self.run_tests(context) : Nil
      {% names = @type.methods.map(&.name).select(&.starts_with?("test__")) %}

      context.test_suite(self.class) do
        {% for name in names %}
          %test = new(context)
          %test.call("{{name}}") { %test.{{ name }} }
        {% end %}
      end

      nil
    end

    def call(name)
      context.test_case(name) do
        before_hooks

        result = capture_exception(name) do
          yield
        end

        context.record_result(result)

        after_hooks
      end

      nil
    end

    def capture_exception(name)
      begin
        yield
      rescue ex : Exception
        TestResult.failure(self.class.name, name, ex)
      else
        TestResult.success(self.class.name, name)
      end
    end

    def before_hooks
      # FIXME
    end

    def after_hooks
      # FIXME
    end

  end

end
