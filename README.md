# microtest

A very tiny testing framework inspired by minitest/minitest.cr.

## Features

- This framework is opinionated
- It uses power asserts by default. There are no `assert_equals`, `assert_xyz`, just power asserts
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
require "microtest"

Microtest.around do
  DB.transaction do
    yield
  end
end

include Microtest::DSL
Microtest.run!(reporters: [MyFancyReporter.new] of Reporter)
```


## Development

I am using guardian to run the tests on each change. Also the guardian task uses
the computer voice to report build/test failure/success.

## DONE

- hooks (before, after, around), and global ones for e.g. global transactional fixtures
- Customizable reporters
- Capture timing info

## TODO

- crtl+c to halt tests
- fail fast
- Randomization + configurable seed
- Number of tests and assertions
- Focus & skip
- Reporter: list N slowest tests
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
