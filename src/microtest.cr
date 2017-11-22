require "colorize"

require "./microtest/backtrace_printer"
require "./microtest/exceptions"
require "./microtest/test_result"
require "./microtest/execution_context"
require "./microtest/power_assert"
require "./microtest/test"
require "./microtest/runner"
require "./microtest/reporter"

module Microtest
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

  def self.run(reporters : Array(Reporter) = [ProgressReporter.new, ErrorListReporter.new, SlowTestsReporter.new, SummaryReporter.new] of Reporter, random_seed : UInt32 = ENV.fetch("SEED", Random.new.next_u.to_s).to_u32)
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
