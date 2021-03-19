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

  def self.fetch_seed : UInt32
    ENV.fetch("SEED", Random.new.next_u.to_s).to_u32
  end

  COMMON_REPORTERS  = [ErrorListReporter.new, SlowTestsReporter.new, SummaryReporter.new] of Reporter
  DEFAULT_REPORTERS = [ProgressReporter.new] + COMMON_REPORTERS

  def self.run(reporters : Array(Reporter), random_seed = fetch_seed)
    runner = DefaultRunner.new(reporters, random_seed)
    runner.call
  end

  def self.run!(reporting : Symbol = :progress, *args)
    reporters = case reporting
                when :descriptions
                  [Microtest::DescriptionReporter.new] + COMMON_REPORTERS
                when :progress
                  DEFAULT_REPORTERS
                else raise "Invalid reporting type: #{reporting}"
                end

    run!(reporters, *args)
  end

  def self.run!(*args)
    success = run(*args)
    exit(success ? 0 : -1)
  end

  module DSL
    macro describe(cls, focus = :nofocus, &block)
      class {{cls.id}}Test < Microtest::Test
        {{block.body}}
      end
    end
  end
end
