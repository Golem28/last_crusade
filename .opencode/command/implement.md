---
description: Implement a user story end-to-end via the orchestrator agent
agent: orchestrator
---

Implement the following user story in this Godot project end-to-end.

User story:
$ARGUMENTS

Run your full workflow: delegate the implementation to the `developer` subagent, have `test_writer` write unit tests for the new code, have `tester` run the test suite, and have `reviewer` review the result. Loop back to fix any failing tests or blocking review findings until everything passes, then summarize what was implemented, the files changed, and the final test results.
