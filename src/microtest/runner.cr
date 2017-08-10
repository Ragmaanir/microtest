module Microtest
  abstract class Runner
    getter reporters : Array(Reporter)
    getter suites
    getter random_seed : UInt32

    def initialize(@reporters : Array(Reporter), @random_seed : UInt32, @suites = Test.test_classes)
    end

    abstract def call
  end

  class DefaultRunner < Runner
    def call
      ctx = ExecutionContext.new(reporters, suites, random_seed)
      ctx.started

      begin
        suites.shuffle(ctx.random).each do |suite|
          suite.run_tests(ctx)
        end
      rescue e : FatalException
      end

      ctx.finished

      !ctx.errors? && !ctx.aborted?
    end
  end
end
