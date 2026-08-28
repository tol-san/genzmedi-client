# GEMINI.md - Flutter Client Instructions & MCP Tool Guidelines

This workspace is the Flutter mobile client for GenZ Media.

## Available MCP Tools & Operations

1. **Dart MCP Server (`dart-mcp-server`)**:
   - Flutter static analysis, package lookups, and widget inspection.

2. **Context7 MCP (`context7`)**:
   - Official documentation lookup for Flutter, Riverpod, GoRouter, and Dart libraries.

3. **GitHub MCP (`github`)**:
   - Creating/reviewing PRs, checking commits, and managing GitHub issues.

---

## Development & Testing Workflow Rules
- **Synchronize Documentation on Changes**: Whenever adding a new feature, endpoint, schema, or changing existing architecture/APIs, ALWAYS update the corresponding documentation in `client/docs/` and `server/docs/` immediately to maintain 100% consistency between documentation and code.
- **Implement Tests on Changes**: Always implement relevant tests (Unit, Widget, or Integration test where appropriate) after implementing a new feature or making changes to prevent regressions.
- **Pragmatic Testing**: Focus on critical business logic, API error handling, state transitions, and core UI user journeys. It is not necessary to write exhaustive or redundant tests for every single detail.
- **Verification**: Always run `flutter test` & `flutter analyze` for the Flutter client before wrapping up changes.

