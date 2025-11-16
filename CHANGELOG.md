# Changelog

### 1.2.9

- Crystal 1.18
- Fix miscellaneous spec failures for Crystal 1.18 (#3, Thanks @HertzDevil)
- Support Windows MSVC / MinGW-w64 (#4, Thanks @HertzDevil)

### 1.2.8

- Minor line number fix for crystal 1.16.0
- Backtrace fix for crystal 1.16.0

### 1.2.7

- Changed dark blue in reporter to light blue
- Highlight errors headline in error list reporter
- Highlight test method in backtraces
- Use Colorize::ColorRGB for better colors
- Fix deprecated `splat/double_splat`

### 1.2.6

- Crystal 1.10.0-dev (no fixes needed)
- Fixed named argument inspection in power asserts

### 1.2.5

- Crystal 1.4
- Reorganize some specs (move hooks spec and hook example files)
- Add test for order of hooks
- Add compilation error specs
- Move management scripts for generating README and releasing to cli.cr and ./cli
- Abort execution in Microtest.bug
- Abort when backtrace printer failes to classify backtrace entries (using BACKTRACE_ERRORS=true)
- Rename context "errors" to "failures"
- Rename spec helper macros, unify them, use "crystal run" instead of "eval" to avoid backtrace printer problems

### 1.2.4

- Power asserts evaluate expressions only once
- New power assert formatting
- Adde more detailed power assert specs
- Crystal 1.0

### 1.2.3

### 1.2.1

- Fix backtrace printing by using Crystal::PATH (crystal 0.26.0)

### 1.1.1

- Added timing info to DescriptionReporter
- Fixed timing-output in terminal

### 1.1.0

- abort tests
- limit power assert output depth
- update crystal to 0.24.0 (pre-release)
- fix around hooks

### 1.0.0

### 0.10.0

- Summary reporter: highlights whether focus is used or not
- JsonReporter: restructure output: list of tests and meta-information
- Examples: Embed tested examples in README automatically by running `build.cr`
- Examples: Generate test output images via aha/wkhtmltoimage using docker
