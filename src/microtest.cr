require "power_assert"
require "./microtest/*"

module Microtest

  def self.run
    DefaultRunner.new.call
  end

  abstract class Runner
    abstract def call
  end

  class DefaultRunner < Runner
    def call
      ctx = DefaultExecutionContext.new
      Test.test_classes.each{ |testcase| testcase.run_tests(ctx) }
    end
  end

  abstract class TestExecutionContext
    abstract def record_exception(ex : Exception)
  end

  class DefaultExecutionContext < TestExecutionContext
    def record_exception(ex : Exception)
      # FIXME
    end
  end

  module TestClassDSL

    macro before(&block)
    end

    macro after(&block)
    end

    macro it(name="anonymous", focus=:nofocus, &block)
      def test__{{name.id}}
        {{block.body}}
      end
    end
  end

  module TestMethodDSL
    include PowerAssert
  end

  class Test
    include TestClassDSL

    private def context
      @context
    end

    def initialize(@context : TestExecutionContext)
    end

    macro def self.test_classes : Array(Test.class)
      [{{ @type.all_subclasses.join(", ").id }}] of Test.class
    end

    macro def self.run_tests(context) : Nil
      {% names = @type.methods.map(&.name).select(&.starts_with?("test__")) %}

      {% for name in names %}
        %test = new(context)
        %test.call { %test.{{ name }} }
      {% end %}

      nil
    end

    def call
      run_before_hooks

      capture_exception(context) do
        yield
      end

      run_after_hooks

      nil
    end

    def capture_exception(context)
      begin
        yield
      rescue ex : Exception
        context.record_exception(ex)
        # FIXME
      end
    end

    def run_before_hooks
      # FIXME
    end

    def run_after_hooks
      # FIXME
    end
  end

  module DSL
    macro describe(cls, focus=:nofocus, &block)
      class {{cls.id}}Test < Microtest::Test
        {{block.body}}
      end
    end
  end

end
