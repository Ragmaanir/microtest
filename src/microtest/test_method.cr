module Microtest
  class TestMethod
    getter suite : Test.class
    getter name : String
    getter sanitized_name : String
    getter method_name : String
    getter focus : Bool | String
    getter skip : Bool
    getter block : (TestMethod, ExecutionContext) ->

    def initialize(@suite, @name, @sanitized_name, @method_name, @focus, @skip, &@block : (TestMethod, ExecutionContext) ->)
    end

    def focus?
      focus
    end

    def skip?
      skip
    end

    def full_name
      [suite, sanitized_name].join(MEHTOD_SEPARATOR)
    end

    def call(ctx : ExecutionContext)
      block.call(self, ctx)
    end
  end
end
