# microtest

A very tiny testing framework inspired by minitest/minitest.cr.

## Features

- This framework is opinionated
- It uses power asserts by default. There are no `assert_equals`, `assert_xyz`, just power asserts (except for `assert_raises`)
- It uses the spec syntax for test case structure (`describe`, `test`, `before`, `after`). Reasons: No test-case name-clashes when using describe. Not forgetting to call super in setup/teardown methods.
- No nesting of describe blocks. IMO nesting of those blocks is an anti-pattern.
- No let-definitions. Only before / after hooks. Use local variables mostly.
- Tests have to be started explicitly by `Microtest.run`, no at-exit hook.

## Installation


Add this to your application's `shard.yml`:

```yaml
dependencies:
  microtest:
    github: ragmaanir/microtest
```


## Usage


```crystal
# spec_helper.cr
require "microtest"

Microtest.around do
  DB.transaction do
    yield
  end
end

include Microtest::DSL
Microtest.run!(reporters: [MyFancyReporter.new] of Reporter)

# water_pump_spec.cr
describe MyLib::WaterPump do
  test "that it pumps water" do
    p = MyLib::WaterPump.new("main")
    p.enable
    p.start

    assert(p.pumps_water?)
  end

  test "that it pumps with a certain speed" do
    p = MyLib::WaterPump.new("main", speed: 100)
    p.enable
    p.start

    assert(p.pump_speed > 50)
  end
end
```

When a power-assert fails you get output like this:

```crystal
assert 2**5 == 4 * 2**4

# output
# - subexpressions first
# - complete expression last
# - expression on the left, result on the right
2 ** 5           : 32
2 ** 4           : 16
4 * (2 ** 4)     : 64
(2 ** 5) == (4 * (2 ** 4)) : false
```


## Development

I am using guardian to run the tests on each change. Also the guardian task uses
the computer voice to report build/test failure/success.

## DONE

- hooks (before, after, around), and global ones for e.g. global transactional fixtures
- Customizable reporters
- Capture timing info
- Randomization + configurable seed
- Reporter: list N slowest tests
- assert_raises
- skip
- Write real tests for Microtest (uses JSON report to check for correct test output). Now tests are green.
- JSON reporter

## TODO

- crtl+c to halt tests
- fail fast
- Number of tests and assertions
- focus
- Alternatives to nesting? (Use separate describe blocks)
- Group tests and specify hooks and helper methods for the group only
- save results to file and compare current results to last results, including timings

## Problems

- Display correct line numbers. This is difficult since macros are used everywhere.

## Contributing

1. Fork it ( https://github.com/ragmaanir/microtest/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [ragmaanir](https://github.com/ragmaanir) ragmaanir - creator, maintainer
