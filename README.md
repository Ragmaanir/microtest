# 🔬 microtest [![Build Status](https://travis-ci.org/Ragmaanir/microtest.svg?branch=master)](https://travis-ci.org/Ragmaanir/microtest)

### Version 1.2.3

A very tiny testing framework inspired by minitest/minitest.cr.

## Features

- This framework is opinionated
- It uses power asserts by default. There are no `assert_equals`, `assert_xyz`, just power asserts (except for `assert_raises`)
- It uses the spec syntax for test case structure (`describe`, `test`, `before`, `after`). Reasons: No test-case name-clashes when using describe. Not forgetting to call super in setup/teardown methods.
- No nesting of describe blocks. IMO nesting of those blocks is an anti-pattern.
- No let-definitions. Only before / after hooks. Use local variables mostly.
- Tests have to be started explicitly by `Microtest.run!`, no at-exit hook.
- Colorized and abbreviated exception stacktraces
- Randomized test order (SEED can be specified as environment variable)
- Focus individual tests (`test! "my test" do ...`)
- Different reportes (progress, descriptions, slow tests)

## Installation


Add this to your application's `shard.yml`:

```yaml
development_dependencies:
  microtest:
    github: ragmaanir/microtest
    version: ~> 1.2.3
```

And add this to your `spec_helper.rb`:

```crystal
require "microtest"

include Microtest::DSL

Microtest.run!
```


## Usage

```crystal
class WaterPump
  getter name : String
  getter speed : Int32
  getter? enabled : Bool = false

  def initialize(@name, @speed = 10)
  end

  def enable
    @enabled = true
  end
end

describe WaterPump do
  test "enabling" do
    p = WaterPump.new("main")
    p.enable

    assert(p.enabled?)
  end

  test "pump speed" do
    p = WaterPump.new("main", speed: 100)

    assert(p.speed > 50)
  end

  test "this one is pending since it got no body"

  pending "this one is pending even though it has a body" do
    raise "should not raise"
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

![missing](file?raw=true)

### Microtest Test Output (microtest tests using progress reporter)

![missing](file?raw=true)

## Reporters

Use common reporter combinations:

```crystal
# both versions include error-list-, slow-tests- and summary-reporters:
Microtest.run!(:progress)
Microtest.run!(:descriptions)
```

Or select the used reporters explicitly:

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
![missing](file?raw=true)

### Description Reporter
![missing](file?raw=true)

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

![missing](file?raw=true)

## Development

I am using guardian to run the tests on each change. Also the guardian task uses the computer voice to report build/test failure/success.
Run `bin/build` to run tests and generate `README.md` from `README.md.template` and generate the images of the test outputs (using an alpine docker image).
