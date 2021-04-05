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
            break if ctx.halted?
            c.call(ctx)
          end
        end
      end

      nil
    end

    def run_test(meth : TestMethod, &block)
      name = meth.sanitized_name
      time = Time.local

      test_exc = SkipException.new("before-hook failed", "", 0)
      hook_exc = nil

      begin
        around_hooks do
          before_hooks

          begin
            if meth.skip?
              # test_exc = SkipException.new("pending", "", 0)
              skip("pending")
            else
              block.call
            end
          rescue ex : AssertionFailure | SkipException
            test_exc = ex
          rescue ex : Exception
            test_exc = UnexpectedError.new(self.class.name, name, ex)
          else
            test_exc = nil # passed
          end

          after_hooks
        end
      rescue e
        hook_exc = HookException.new(self.class.name, name, e)

        context.abort!(hook_exc)
      end

      duration = Time.local - time

      context.record_result(self.class.name, meth, duration, test_exc, hook_exc)

      nil
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
