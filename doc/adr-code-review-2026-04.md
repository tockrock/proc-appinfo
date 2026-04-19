# ADR: Code review decisions — April 2026

## Status

Accepted

## Context

A full code review was conducted covering field ordering, error handling, output correctness, API design, test coverage, feature scope, Swift conventions, and human readability. For each perspective, the options were: change the code, or accept the current state as intentional.

## Decisions

### 1. Field ordering consistency

Reordered all surfaces (struct, CLI flags, output functions, README) to follow: **Identity → Version → Process → Paths → Runtime state**. `.sortedKeys` removed from `JSONEncoder` so JSON output follows struct order.

### 2. Force unwraps in `jsonOutput`

```swift
let data = try! encoder.encode(info)
return String(data: data, encoding: .utf8)!
```

Both force unwraps are kept as-is. `AppInfo` contains only standard `Codable` types so encoding cannot fail, and `JSONEncoder` always produces valid UTF-8. Using `try?` with a fallback would silently swallow a violated invariant; making the call chain `throws` adds complexity for an error that cannot occur. A loud crash on the impossible is preferable to silent empty output.

### 3. Nil vs empty string in single-field mode

When a field flag (e.g. `--bundle-name`) resolves to nil, output is `""`. Scripts cannot distinguish nil from empty string; the tool exits 0 in both cases. Accepted as-is — changing this would require exit-code additions or a sentinel value, which is out of scope for now.

### 4. Redundant derived fields in `AppInfo`

`architectureName` and `activationPolicyName` are stored fields derived from raw Int fields. They could be computed properties. Accepted as-is — the current approach is explicit and has no practical downside at this scale.

### 5. `--from-pid` validation

No guard against 0 or negative PIDs. An invalid PID silently produces a generic "not found" error. Accepted as-is — the error is still surfaced; precise validation messaging is a polish concern.

### 6. Test coverage

Zero tests exist. Core logic is DI-friendly and testable. Accepted as-is for now — adding tests is worthwhile but not blocking.

### 7. Feature completeness

Known gaps: no `--all` mode, `--from-pid` walks from the given PID rather than its parent, no granular exit codes, `launchDate` always uses local timezone. All accepted as-is — these are future feature candidates, not defects.

### 8. Swift conventions

`@usableFromInline` on `parentPID` and `makeAppInfo` without `@inlinable` is a no-op. Static helpers `architectureName(_:)` and `activationPolicyName(_:)` on the model are unconventional. Accepted as-is — neither causes incorrect behaviour; cleanup can happen alongside future refactoring.

### 9. Human readability

`selectedFields` is an unlabelled `Bool` array. `output()` grows an if-chain. Label strings in `humanOutput()` duplicate `@Flag` help text with no cross-check. Accepted as-is — fragility is low at the current field count.

## Consequences

Items 2–9 are known trade-offs, not oversights. If any of these surfaces as a real problem, the relevant perspective above captures the context needed to make a fresh decision.
