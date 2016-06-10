require "colorize"

require "./microtest/string_formatting"
require "./microtest/test_result"
require "./microtest/execution_context"
require "./microtest/power_assert"
require "./microtest/test"
require "./microtest/runner"
require "./microtest/reporter"

module Microtest
  class AssertionFailure < Exception
    getter file : String
    getter line : Int32

    def initialize(msg, @file, @line)
      super(msg)
    end
  end

  class Skip < Exception
  end

  class UnexpectedError < Exception
    getter exception, test

    def initialize(@test : String, @exception : Exception)
      super("Unexpected error in #{test}: #{exception.message}")
    end
  end

  module GlobalHookDSL
    macro around(&block)
      class Microtest::Test
        def around_hooks
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

  def self.run(reporters : Array(Reporter) = [ProgressReporter.new, ErrorListReporter.new, SummaryReporter.new] of Reporter)
    runner = DefaultRunner.new(reporters)
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
