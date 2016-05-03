require "../src/microtest"

include Microtest::DSL
success = Microtest.run
exit success ? 0 : -1
