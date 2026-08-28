# Flutter Client Development & Testing Guidelines

## Guidelines for Agents
- **Implement Tests on Changes**: Always implement relevant tests (Unit, Widget, or Integration test where appropriate) after implementing a new feature or making changes.
- **Pragmatic Testing**: Focus on critical business logic, state transitions, API error handling, and core UI user flows. Exhaustive/redundant tests are not required.
- **Verification**: Run `flutter test` and `flutter analyze` to ensure 0 errors/warnings.
- **Commit & Push**: After verification passes, commit and push changes with conventional commit messages.
