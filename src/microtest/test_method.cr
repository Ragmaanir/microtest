module Microtest
  class TestMethod
    getter name : String, focus : Bool | String, skip : Bool
    getter block : (TestMethod, ExecutionContext) ->

    def initialize(@name, @focus, @skip, &@block : (TestMethod, ExecutionContext) ->)
    end

    def focus?
      focus
    end

    def skip?
      skip
    end

    def sanitized_name
      name.gsub(/[^a-zA-Z0-9_]/, "_")
    end

    def method_name
      "test__#{sanitized_name}"
    end

    def call(ctx : ExecutionContext)
      block.call(self, ctx)
    end
  end
end
