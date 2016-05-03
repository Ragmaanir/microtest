module Microtest

  abstract class Runner
    getter reporters : Array(Reporter)

    def initialize(@reporters : Array(Reporter))
    end

    abstract def call
  end

  class DefaultRunner < Runner
    def call
      suites = Test.test_classes
      methods = suites.map(&.test_methods.size)
      
      ctx = DefaultExecutionContext.new(reporters)
      ctx.started
      Test.test_classes.each{ |testcase| testcase.run_tests(ctx) }
      reporters.each(&.finish(ctx))
      !ctx.errors?
    end
  end

end
