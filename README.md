# microtest

A very tiny testig framework inspired by minitest/minitest.cr. Differences are:

- This framework is opinionated
- It uses power asserts by default. There are no `assert_equals`, `assert_xyz`, just power asserts
- It uses the spec syntax for test case structure
- No nesting of describe blocks. IMO nesting of those blocks is an anti-pattern.
- No let-definitions. Only before / after hooks.
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

include Microtest::DSL
Microtest.run
```


## Development

I am using guardian to run the tests on each change. Also the guardian task uses
the computer voice to report build/test failure/success.

## Contributing

1. Fork it ( https://github.com/ragmaanir/microtest/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [ragmaanir](https://github.com/ragmaanir) ragmaanir - creator, maintainer
