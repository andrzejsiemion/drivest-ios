<!--
Sync Impact Report
==================
- Version change: 0.0.0 → 1.0.0
- Modified principles: N/A (initial creation)
- Added sections:
  - Principle I: Clean Code
  - Principle II: Simple UX
  - Principle III: Responsive Design
  - Principle IV: Minimal Dependencies
  - Section: iOS Platform Constraints
  - Section: Development Workflow
  - Governance
- Removed sections: None
- Templates requiring updates:
  - .specify/templates/plan-template.md ✅ No updates needed (generic structure)
  - .specify/templates/spec-template.md ✅ No updates needed (generic structure)
  - .specify/templates/tasks-template.md ✅ No updates needed (generic structure)
- Follow-up TODOs: None
-->

# Fuel Tracker Constitution

## Core Principles

### I. Clean Code

All source code MUST be readable, well-structured, and maintainable.

- Functions MUST do one thing and do it well (Single Responsibility)
- Naming MUST be descriptive and consistent — no abbreviations
  unless universally understood (e.g., `URL`, `ID`)
- No dead code, commented-out code, or TODO markers in merged branches
- Swift conventions MUST be followed: protocol-oriented design,
  value types preferred over reference types where appropriate
- Code MUST compile without warnings

**Rationale**: An iOS app maintained by a small team requires code
that any contributor can understand quickly without tribal knowledge.

### II. Simple UX

The user interface MUST prioritize clarity and speed of interaction.

- Every screen MUST have a single, obvious primary action
- Data entry MUST require the fewest possible taps
- Navigation depth MUST NOT exceed 3 levels from the root
- No unnecessary confirmation dialogs — use undo patterns instead
- Empty states MUST guide the user toward the next action

**Rationale**: Vehicle cost tracking is a utility task. Users want to
log expenses quickly and move on — friction causes abandonment.

### III. Responsive Design

The UI MUST adapt gracefully to all supported device sizes and
orientations.

- Layouts MUST use Auto Layout or SwiftUI adaptive containers
- Text MUST support Dynamic Type (accessibility sizes)
- The app MUST be usable in both portrait and landscape on iPhone
  and iPad
- No hardcoded dimensions — use relative sizing and safe area insets
- Dark Mode MUST be fully supported

**Rationale**: iOS users expect apps to work on any device they own
without visual glitches or truncated content.

### IV. Minimal Dependencies

The project MUST minimize external third-party dependencies.

- Prefer Apple-provided frameworks (SwiftUI, CoreData, Charts)
  over third-party equivalents
- A new dependency MUST be justified: what Apple framework was
  insufficient and why?
- Maximum of 5 third-party packages at any time
- Dependencies MUST be managed via Swift Package Manager only
- No dependency may pull in transitive sub-dependencies exceeding
  3 levels deep

**Rationale**: Third-party libraries introduce update burden, binary
size growth, and supply-chain risk. Apple frameworks receive long-term
support aligned with the OS lifecycle.

## iOS Platform Constraints

- **Minimum deployment target**: iOS 17.0
- **Language**: Swift 5.9+
- **UI framework**: SwiftUI (UIKit permitted only for capabilities
  not yet available in SwiftUI)
- **Storage**: SwiftData or CoreData for local persistence
- **Architecture**: MVVM with clear separation between View,
  ViewModel, and Model layers
- **Testing**: XCTest for unit tests; XCUITest for UI tests
- **No server dependency**: The app MUST function fully offline;
  cloud sync is optional and additive

## Development Workflow

- Every feature MUST be developed on a feature branch
- Code MUST pass all tests before merge
- Each commit MUST represent a single logical change
- UI changes MUST be verified on at least iPhone SE (small) and
  iPhone 15 Pro Max (large) simulators
- Accessibility audit (VoiceOver navigation) MUST pass before
  any screen is considered complete

## Governance

- This constitution supersedes all ad-hoc decisions during
  development
- Amendments require: (1) written justification, (2) update to
  this document, (3) review of dependent templates
- Complexity beyond these principles MUST be justified in writing
  within the relevant plan or spec document
- Version follows Semantic Versioning: MAJOR for principle
  removals/redefinitions, MINOR for additions, PATCH for
  clarifications

**Version**: 1.0.0 | **Ratified**: 2026-04-19 | **Last Amended**: 2026-04-19
