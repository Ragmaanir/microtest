
## DONE

- [x] hooks (before, after, around), and global ones for e.g. global transactional fixtures
- [x] Customizable reporters
- [x] Capture timing info
- [x] Randomization + configurable seed
- [x] Reporter: list N slowest tests
- [x] `assert_raises`
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
- [ ] release-script: check that changelog has an entry for the release
- [ ] More robust test for backtrace printer
- [ ] Check whether some assertion failures still cause segfaults
- [ ] Benchmarking feature: Run specific tests as benchmark tests and record their results in a file
