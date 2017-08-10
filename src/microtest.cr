require "colorize"

require "./microtest/backtrace_printer"
require "./microtest/test_result"
require "./microtest/execution_context"
require "./microtest/power_assert"
require "./microtest/test"
require "./microtest/runner"
require "./microtest/reporter"

module Microtest
  class StandardException < Exception
    getter file : String
    getter line : Int32

    def initialize(msg, @file, @line)
      super(msg)
    end
  end

  class AssertionFailure < StandardException
  end

  class SkipException < StandardException
  end

  class UnexpectedError < StandardException
    getter exception : Exception
    getter suite : String
    getter test : String

    def initialize(@suite, @test, @exception)
      # super("Unexpected error in #{suite}##{test}: #{exception.message}")
      # super("Unexpected error: #{exception.message}", exception.file, exception.line)
      super("Unexpected error: #{exception.message}", "unknown", 0)
    end
  end

  class HookException < UnexpectedError
    getter test_exception : StandardException | Symbol | Nil

    def initialize(suite, test, exception, @test_exception)
      super(suite, test, exception)
    end
  end

  class FatalException < Exception
  end

  module GlobalHookDSL
    macro around(&block)
      class Microtest::Test
        def around_hooks(&block)
          {{block.body}}
        end
      end
    end

    macro before(&block)
      class Microtest::Test
        def before_hooks
          {{block.body}}
        end
      end
    end

    macro after(&block)
      class Microtest::Test
        def after_hooks
          {{block.body}}
        end
      end
    end
  end

  include GlobalHookDSL

  def self.power_assert_formatter
    @@formatter ||= PowerAssert::ListFormatter.new
  end

  def self.run(reporters : Array(Reporter) = [ProgressReporter.new, ErrorListReporter.new, SlowTestsReporter.new, SummaryReporter.new] of Reporter, random_seed : UInt32 = ENV.fetch("SEED", Random.new_seed.to_s).to_u32)
    runner = DefaultRunner.new(reporters, random_seed)
    runner.call
  end

  def self.run!(*args)
    success = run(*args)
    exit success ? 0 : -1
  end

  module DSL
    macro describe(cls, focus = :nofocus, &block)
      class {{cls.id}}Test < Microtest::Test
        {{block.body}}
      end
    end
  end
end
