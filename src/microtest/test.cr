module Microtest
  module TestClassDSL
    macro around(&block)
      def around_hooks
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

    macro test(name = "anonymous", focus = :nofocus, &block)
      def test__{{name.gsub(/\s+/, "_").id}}
        {{block.body}}
      end
    end
  end

  class Test
    include TestClassDSL
    include Microtest::PowerAssert

    getter context : ExecutionContext

    def initialize(@context)
    end

    macro def self.test_classes : Array(Test.class)
      {{ ("[" + @type.all_subclasses.join(", ") + "] of Test.class").id }}
    end

    macro def self.test_methods : Array(String)
      {% begin %}
        {% names = @type.methods.map(&.name).select(&.starts_with?("test__")) %}
        {% if names.empty? %}
          [] of String
        {% else %}
          [{{*names.map(&.stringify)}}]
        {% end %}
      {% end %}
    end

    macro def self.run_tests(context) : Nil
      {% begin %}
        {% names = @type.methods.map(&.name).select(&.starts_with?("test__")) %}

        context.test_suite(self.class) do
          calls = [
            {% for name in names %}
              -> {
                test = new(context)
                test.call("{{name}}") { test.{{ name }} }
              },
            {% end %}
          ]

          calls.shuffle(context.random).each(&.call)
        end
      {% end %}

      nil
    end

    def call(name)
      context.test_case(name) do
        around_hooks do
          before_hooks

          time = Time.now.epoch_ms
          exc = capture_exception(name) do
            yield
          end
          duration = (Time.now.epoch_ms - time).to_i32

          if exc
            context.record_result(TestResult.failure(self.class.name, name, Duration.milliseconds(duration), exc))
          else
            context.record_result(TestResult.success(self.class.name, name, Duration.milliseconds(duration)))
          end

          after_hooks
        end
      end

      nil
    end

    def capture_exception(name)
      begin
        yield
        nil
      rescue ex : AssertionFailure
        ex
      rescue ex : Exception
        UnexpectedError.new(self.class.name, name, ex)
      end
    end

    def around_hooks
      yield
    end

    def before_hooks
    end

    def after_hooks
    end

    def pass
    end

    def fail(msg, file, line)
      # raise AssertionFailure.new(msg, file, line)
      raise AssertionFailure.new(msg, file, line)
    end
  end
end
