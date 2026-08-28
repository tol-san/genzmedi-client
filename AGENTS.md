# AGENTS.md - Flutter Client Instructions & MCP Tools Guide

This repository (`client/`) contains the Flutter / Dart mobile client for GenZ Media.

## Technology Stack
- **Framework**: Flutter 3.x / Dart 3.13+
- **State Management**: `flutter_riverpod`
- **Routing**: `go_router`
- **Networking**: `dio`
- **Storage**: `flutter_secure_storage`, `shared_preferences`

---

## Active & Available MCP Tools

1. **Dart MCP Server (`dart-mcp-server`)**:
   - `analyze_files`: Run static analysis on Dart code.
   - `pub_dev_search`: Search pub.dev for packages and dependencies.
   - `widget_inspector`: Inspect Flutter widget trees.
   - `flutter_driver_command` & testing utilities.

2. **Context7 MCP (`context7`)**:
   - Query latest official documentation and code snippets for Flutter, Riverpod, GoRouter, Dio, and pub.dev packages.

3. **GitHub MCP (`github`)**:
   - Manage pull requests, issues, commits, and code review for the client repository.

---

## Development & Testing Workflow Rules
- **Synchronize Documentation on Changes**: Whenever adding a new feature, endpoint, schema, or changing existing architecture/APIs, ALWAYS update the corresponding documentation in `client/docs/` and `server/docs/` immediately to maintain 100% consistency between documentation and code.
- **Implement Tests on Changes**: Always implement relevant tests (Unit, Widget, or Integration test where appropriate) after implementing a new feature or making changes to prevent regressions.
- **Pragmatic Testing**: Focus on critical business logic, API error handling, state transitions, and core UI user journeys. It is not necessary to write exhaustive or redundant tests for every single detail.
- **Verification**: Always run `flutter test` & `flutter analyze` for the Flutter client before wrapping up changes.

