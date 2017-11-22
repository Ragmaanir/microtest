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

  class Test
    include TestClassDSL
    include Microtest::PowerAssert

    GENERAL_TESTNAME_PREFIX = "__test"
    FOCUSED_TESTNAME_PREFIX = "__testf"
    GENERAL_TESTNAME_REGEX  = /__test(f)?__/

    getter context : ExecutionContext

    def initialize(@context)
    end

    def self.test_classes : Array(Test.class)
      {{ ("[" + @type.all_subclasses.join(", ") + "] of Test.class").id }}
    end

    def self.using_focus? : Bool
      {{
        @type.all_subclasses.any? do |c|
          c.methods.map(&.name).any?(&.starts_with?(FOCUSED_TESTNAME_PREFIX))
        end
      }}
    end

    def self.test_methods : Array(String)
      {% begin %}
        {%
          using_focus = @type.all_subclasses.any? do |c|
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
    def self.run_tests(context) : Nil
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

            calls.shuffle(context.random).each do |c|
              break if context.abortion_forced?
              c.call
            end
          end
        {% end %}
      {% end %}

      nil
    end

    def call(name, &block)
      context.test_case(name) do
        time = Time.now
        exc = execute_test(name, &block)

        duration = Time.now - time

        if !context.abortion_forced?
          case e = exc
          when HookException
            report_test_result(name, duration, e.test_exception)
            context.abort!(e)
            raise FatalException.new
          else
            report_test_result(name, duration, e)
          end
        end
      end

      nil
    end

    def report_test_result(name, duration, e)
      case e
      when AssertionFailure
        context.record_result(TestResult.failure(self.class.name, name, duration, e))
      when UnexpectedError
        context.record_result(TestResult.failure(self.class.name, name, duration, e))
      when SkipException
        context.record_result(TestResult.skip(self.class.name, name, duration, e))
      when nil # not :not_executed
        context.record_result(TestResult.success(self.class.name, name, duration))
      end
    end

    def execute_test(name, &block)
      exc = :not_executed

      around_hooks do
        before_hooks

        exc = capture_exception(name, &block)

        after_hooks
      end
    rescue e
      HookException.new(self.class.name, "Hook before/after/around raised in #{name}", e, exc)
    else
      exc
    end

    def capture_exception(name, &block)
      block.call
      nil
    rescue ex : AssertionFailure | SkipException
      ex
    rescue ex : Exception
      UnexpectedError.new(self.class.name, name, ex)
    end

    def around_hooks(&block)
      block.call
    end

    def before_hooks
    end

    def after_hooks
    end

    def pass
    end

    macro fail(msg)
      raise Microtest::AssertionFailure.new({{msg}}, {{msg.filename}}, {{msg.line_number}})
    end

    macro fail(msg, file, line)
      raise Microtest::AssertionFailure.new({{msg}}, {{file}}, {{line}})
    end

    macro skip(msg)
      raise Microtest::SkipException.new({{msg}}, {{msg.filename}}, {{msg.line_number}})
    end

    macro skip(msg, file, line)
      raise Microtest::SkipException.new({{msg}}, {{file}}, {{line}})
    end
  end
end
