require "power_assert"
require "colorize"

require "./microtest/test_result"
require "./microtest/execution_context"
require "./microtest/test"
require "./microtest/runner"
require "./microtest/reporter"

module Microtest

  def self.run(reporters : Array(Reporter) = [ProgressReporter.new, SummaryReporter.new] of Reporter)
    runner = DefaultRunner.new(reporters)
    runner.call
  end

  module DSL
    macro describe(cls, focus=:nofocus, &block)
      class {{cls.id}}Test < Microtest::Test
        {{block.body}}
      end
    end
  end

end
