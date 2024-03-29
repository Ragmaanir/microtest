require "./microtest/version"
require "./microtest/termart"
require "./microtest/backtrace_printer"
require "./microtest/exceptions"
require "./microtest/test_result"
require "./microtest/test_method"
require "./microtest/execution_context"
require "./microtest/power_assert"
require "./microtest/power_assert_formatter"
require "./microtest/test"
require "./microtest/runner"
require "./microtest/reporter"
require "./microtest/reporters"

module Microtest
  module DSL
    macro describe(cls, &block)
      class {{cls.id}}Test < Microtest::Test

        \{% if @type.has_method?("__microtest_already_defined") %}
          \{% raise "Duplicate describe for: {{cls.id}}" %}
        \{% end %}

        private def __microtest_already_defined
        end

        def self.test_methods
          [] of Microtest::TestMethod
        end

        {{block.body}}
      end
    end
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

  MEHTOD_SEPARATOR = "#"

  def self.bug(msg : String)
    abort("MICROTEST BUG: #{msg}".colorize(:red))
  end

  def self.power_assert_formatter
    @@formatter ||= PowerAssert::ListFormatter.new
  end

  def self.fetch_seed : UInt32
    ENV.fetch("SEED", Random.new.next_u.to_s).to_u32
  end

  COMMON_REPORTERS  = [ErrorListReporter.new, SlowTestsReporter.new, SummaryReporter.new] of Reporter
  DEFAULT_REPORTERS = [ProgressReporter.new] + COMMON_REPORTERS

  def self.reporter_types(reporting : Symbol = :progress)
    case reporting
    when :descriptions, :description
      [Microtest::DescriptionReporter.new] + COMMON_REPORTERS
    when :progress
      DEFAULT_REPORTERS
    else
      raise "Invalid reporting type: #{reporting}"
    end
  end

  def self.run(reporting : Symbol = :progress, *args)
    reporters = reporter_types(reporting)
    run(reporters, *args)
  end

  def self.run(reporters, random_seed = fetch_seed)
    runner = DefaultRunner.new(reporters, random_seed)
    runner.call
  end

  def self.run!(reporting : Symbol = :progress, *args)
    reporters = reporter_types(reporting)
    run!(reporters, *args)
  end

  def self.run!(*args)
    success = run(*args)
    exit(success ? 0 : -1)
  end
end
