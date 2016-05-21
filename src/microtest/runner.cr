module Microtest

  abstract class Runner
    getter reporters : Array(Reporter)
    getter suites

    def initialize(@reporters : Array(Reporter), @suites = Test.test_classes)
    end

    abstract def call
  end

  class DefaultRunner < Runner
    def call
      ctx = ExecutionContext.new(reporters, suites)
      ctx.started

      suites.each do |suite|
        suite.run_tests(ctx)
      end

      puts

      ctx.finished

      !ctx.errors?
    end
  end

end
