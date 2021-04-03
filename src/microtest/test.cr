require "./dsl"

module Microtest
  class Test
    include TestClassDSL
    include Microtest::PowerAssert

    getter context : ExecutionContext

    def initialize(@context)
    end

    def self.test_classes : Array(Test.class)
      {{ ("[" + @type.all_subclasses.join(", ") + "] of Test.class").id }}
    end

    def self.test_methods
      [] of Microtest::TestMethod
    end

    def self.selected_test_methods(ctx : ExecutionContext)
      test_methods.select { |m| !ctx.focus? || m.focus? }
    end

    def self.using_focus?
      test_methods.any?(&.focus?)
    end

    def self.run_tests(ctx : ExecutionContext) : Nil
      tests = selected_test_methods(ctx)

      if !tests.empty?
        ctx.test_suite(self.name) do
          tests.shuffle(ctx.random).each do |c|
            break if ctx.abortion_forced?
            c.call(ctx)
          end
        end
      end

      nil
    end

    def run_test(meth : TestMethod, &block)
      name = meth.sanitized_name

      context.test_case(name) do
        time = Time.local

        if meth.skip?
          exc = SkipException.new("pending", "", 0)
        else
          exc = execute_test(name, &block)
        end

        duration = Time.local - time

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

    def report_test_result(name : String, duration : Time::Span, e : StandardException | Symbol | Nil)
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

    def execute_test(name, &block) : StandardException | Symbol | Nil
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
