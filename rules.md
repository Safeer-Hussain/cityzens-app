# Autonomous Engineering Rules: Cityzens

## "run daily sprint" Protocol

Whenever the user prompts "run daily sprint", execute the following deterministic autonomous sequence:

1. **Locate Next Task**:
   - Open `docs/AUTONOMOUS_BACKLOG.md`.
   - Find the first unchecked sprint formatted as `- [ ] **Sprint XX: ...**`.

2. **Architect & Implement End-to-End**:
   - Implement the complete feature set across data, domain, and presentation layers using strict Clean Architecture + MVVM.
   - Store all persistent models in `AppDatabase` (SQLite) with appropriate tables and migrations.
   - Maintain zero hardcoded colors, ensuring full parity across Dark and Light mode via `Theme.of(context).colorScheme`.
   - Ensure every `FloatingActionButton` defines an explicit, unique `heroTag`.
   - Ensure landscape 360dp safety with independent vertical scrolls and no RenderFlex overflow.
   - Strictly prohibit emojis anywhere in code, strings, logs, or commit messages.

3. **Automated Testing**:
   - Write comprehensive unit and/or widget tests covering new business logic and providers in `test/unit/` or `test/widget/`.
   - Run `flutter analyze` and verify 0 errors/warnings/lints.
   - Run `flutter test` and verify 100% test pass rate.

4. **Backlog & Git Synchronization**:
   - Update `docs/AUTONOMOUS_BACKLOG.md`, changing `- [ ]` to `- [x]` for the completed sprint.
   - Commit the changes using a clean conventional commit message (e.g. `feat(attendance): implement semester gpa what-if calculator with sqlite history`).
   - Push the commit to `origin main`.
   - Report summary of completed sprint, architecture additions, and test results.
