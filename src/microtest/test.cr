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

  class Test
    include TestClassDSL
    include Microtest::PowerAssert

    GENERAL_TESTNAME_PREFIX = "__test"
    FOCUSED_TESTNAME_PREFIX = "__testf"
    GENERAL_TESTNAME_REGEX  = /__test(f)?__/

    getter context : ExecutionContext

    def initialize(@context)
    end

    macro def self.test_classes : Array(Test.class)
      {{ ("[" + Test.all_subclasses.join(", ") + "] of Test.class").id }}
    end

    macro def self.using_focus? : Boolean
      {{
        Test.all_subclasses.any? do |c|
          c.methods.map(&.name).any?(&.starts_with?(FOCUSED_TESTNAME_PREFIX))
        end
      }}
    end

    macro def self.test_methods : Array(String)
      {% begin %}
        {%
          using_focus = Test.all_subclasses.any? do |c|
            c.methods.map(&.name).any?(&.starts_with?(FOCUSED_TESTNAME_PREFIX))
          end

          methods = if using_focus
                      @type.methods.map(&.name).select(&.starts_with?(FOCUSED_TESTNAME_PREFIX)).map(&.stringify)
                    else
                      @type.methods.map(&.name).select(&.starts_with?(GENERAL_TESTNAME_PREFIX)).map(&.stringify)
                    end
        %}
        [ {{ *methods }} ] of String
      {% end %}
    end

    # NOTE:
    # These macro methods are ugly. They contain a lot of duplication,
    # but i don't know how to get rid of it. The duplication seems necessary, since
    # a macro def cannot invoke another macro def. And a macro-level array of
    # method names is required in order to be able to iterate over test method
    # names to generate the "send(...)" like code.
    macro def self.run_tests(context) : Nil
      {% begin %}
        {%
          test_methods = @type.methods.map(&.name).select(&.starts_with?(GENERAL_TESTNAME_PREFIX)).map(&.stringify)

          focus = Test.all_subclasses.any? do |c|
            c.methods.map(&.name).any?(&.starts_with?(FOCUSED_TESTNAME_PREFIX))
          end

          names = if focus
                    test_methods.select(&.starts_with?(FOCUSED_TESTNAME_PREFIX))
                  else
                    test_methods.select(&.starts_with?(GENERAL_TESTNAME_PREFIX))
                  end
        %}

        {% if !names.empty? %}
          context.test_suite(self) do
            calls = [
              {% for name in names %}
                -> {
                  test = new(context)
                  test.call("{{name.id}}".sub(GENERAL_TESTNAME_REGEX, "")) { test.{{ name.id }} }
                },
              {% end %}
            ]

            calls.shuffle(context.random).each(&.call)
          end
        {% end %}
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

          case exc
          when AssertionFailure then context.record_result(TestResult.failure(self.class.name, name, Duration.milliseconds(duration), exc))
          when UnexpectedError  then context.record_result(TestResult.failure(self.class.name, name, Duration.milliseconds(duration), exc))
          when SkipException    then context.record_result(TestResult.skip(self.class.name, name, Duration.milliseconds(duration), exc))
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
      rescue ex : SkipException
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
      raise AssertionFailure.new(msg, file, line)
    end

    macro skip(msg, file = __FILE__, line = __LINE__)
      raise Microtest::SkipException.new({{msg}}, {{file}}, {{line}})
    end
  end
end
