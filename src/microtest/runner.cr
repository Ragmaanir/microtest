module Microtest
  abstract class Runner
    getter reporters : Array(Reporter)
    getter suites
    getter random_seed : UInt32

    def initialize(reporters, @random_seed : UInt32, @suites = Test.test_classes)
      @reporters = reporters.map { |r| r.as(Reporter) }
    end

    abstract def call
  end

  class DefaultRunner < Runner
    def call
      ctx = ExecutionContext.new(reporters, suites, random_seed)
      ctx.started

      Process.on_terminate do |reason|
        ctx.manually_abort!
        Process.restore_interrupts!
      end

      suites.shuffle(ctx.random).each do |suite|
        break if ctx.halted?
        suite.run_tests(ctx)
      end

      ctx.finished

      ctx.success?
    end
  end
end
