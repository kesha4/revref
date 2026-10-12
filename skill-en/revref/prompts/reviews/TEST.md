# TEST — Tests

Finding ID prefix: TEST. Use together with `prompts/common-rules.md`.

Review the quality and coverage of the tests.

If possible, run the tests and the coverage tool and rely on real numbers: how many tests, how many fail, how long a run takes, what the coverage is per module.

Coverage:
- which modules are tested, where the gaps are, which critical paths (money, access rights, data, main user scenarios) are not covered;
- balance of levels: unit, integration, end-to-end;
- gap priority: path criticality × code change frequency.

Quality of the tests themselves:
- do they verify behavior or implementation details; will they survive an honest refactoring;
- brittle and flaky tests: dependence on time, run order, network, randomness, shared state;
- excessive mocking, where the test verifies the mocks rather than the code;
- tests without assertions or with weak assertions, meaningless tests written for the coverage number;
- for key tests, answer: what realistic bug will this test not catch;
- test run speed and running tests in CI.

Propose concrete tests for uncovered areas: name, scenario, input data, expected result — in priority order. For the top 5, provide the test code in the project's style.
