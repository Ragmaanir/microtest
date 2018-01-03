# microtest [![Build Status](https://travis-ci.org/Ragmaanir/microtest.svg?branch=master)](https://travis-ci.org/Ragmaanir/microtest)[![Dependency Status](https://shards.rocks/badge/github/ragmaanir/microtest/status.svg)](https://shards.rocks/github/ragmaanir/microtest)

### Version 1.2.0

A very tiny testing framework inspired by minitest/minitest.cr.

## Features

- This framework is opinionated
- It uses power asserts by default. There are no `assert_equals`, `assert_xyz`, just power asserts (except for `assert_raises`)
- It uses the spec syntax for test case structure (`describe`, `test`, `before`, `after`). Reasons: No test-case name-clashes when using describe. Not forgetting to call super in setup/teardown methods.
- No nesting of describe blocks. IMO nesting of those blocks is an anti-pattern.
- No let-definitions. Only before / after hooks. Use local variables mostly.
- Tests have to be started explicitly by `Microtest.run!`, no at-exit hook.

## Installation


Add this to your application's `shard.yml`:

```yaml
development_dependencies:
  microtest:
    github: ragmaanir/microtest
    version: ~> 1.2.0
```

And add this to your `spec_helper.rb`:

```crystal
require "../src/microtest"

include Microtest::DSL

Microtest.run!
```


## Usage

```crystal
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

  test "this one is pending since it got no body"

  test "only run this focused test", :focus do
  end

  test! "and this one too since it is focused also" do
  end
end

```

Run the test with:

`crystal spec`

You can provide the seed to run the tests in the same order:

`SEED=123 crystal spec`

## Power Assert Output

```crystal
describe AssertionFailure do
  test "assertion failure" do
    a = 5
    b = "aaaaaa"
    assert "a" * a == b
  end
end

```

Generates:

![Assertion Failure](assets/assertion_failure.png?raw=true)

### Microtest Test Output (default reporter)

![Default](assets/spec.png?raw=true)

## Reporters

Select the used reporters:

```crystal
Microtest.run!([
  Microtest::DescriptionReporter.new,
  Microtest::ErrorListReporter.new,
  Microtest::SlowTestsReporter.new,
  Microtest::SummaryReporter.new,
] of Microtest::Reporter)
```

```crystal
describe First do
  test "success" do
  end

  test "skip this"
end

describe Second do
  def raise_an_error
    raise "Oh, this is wrong"
  end

  test "first failure" do
    a = 5
    b = 7
    assert a == b * 2
  end

  test "error" do
    raise_an_error
  end
end

```

### Progress Reporter
![Progress Reporter](assets/progress_reporter.png?raw=true)

### Description Reporter
![Description Reporter](assets/description_reporter.png?raw=true)

### When focus active

```crystal
describe Focus do
  test "not focused" do
  end

  test! "focused" do
  end

  test "focused too", :focus do
  end
end

```

![Focus](assets/focus.png?raw=true)

## Development

I am using guardian to run the tests on each change. Also the guardian task uses the computer voice to report build/test failure/success.
Run `bin/build` to run tests and generate `README.md` from `README.md.template` and generate the images of the test outputs (using an alpine docker image).

## DONE

- [x] hooks (before, after, around), and global ones for e.g. global transactional fixtures
- [x] Customizable reporters
- [x] Capture timing info
- [x] Randomization + configurable seed
- [x] Reporter: list N slowest tests
- [x] assert_raises
- [x] skip
- [x] Write real tests for Microtest (uses JSON report to check for correct test output). Now tests are green.
- [x] JSON reporter
- [x] SummaryRepoter
- [x] Continuous Integration with Travis
- [x] focus
- [x] generate README including examples from specs and terminal screenshots
- [x] Print whether focus is active
- [x] crtl+c to halt tests

## TODO

- [ ] fail fast
- [ ] Number of assertions
- [ ] Alternatives to nesting? (Use separate describe blocks)
- [ ] Group tests and specify hooks and helper methods for the group only
- [ ] save results to file and compare current results to last results, including timings

## Problems

- [ ] Display correct line numbers. This is difficult since macros are used everywhere.
- [ ] Some assertion failures cause segfaults
