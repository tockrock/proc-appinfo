# Code Review Progress

## Status

| # | Perspective | Status |
|---|-------------|--------|
| 1 | Field ordering consistency | Done |
| 2 | Force unwraps in `jsonOutput` | Skipped (revisit later) |
| 3 | Nil vs empty string in single-field mode | Todo |
| 4 | Redundant derived fields in `AppInfo` | Todo |
| 5 | `--from-pid` validation | Todo |
| 6 | Test coverage | Todo |
| 7 | Feature completeness | Todo |
| 8 | Swift conventions | Todo |
| 9 | Human readability | Todo |

---

## Completed

### Perspective 1: Field ordering consistency

Reordered all surfaces to follow: **Identity → Version → Process → Paths → Runtime state**

New order:
1. bundleName
2. bundleDisplayName
3. localizedName
4. bundleId
5. version
6. buildVersion
7. pid
8. architecture
9. architectureName
10. activationPolicy
11. activationPolicyName
12. bundlePath
13. executablePath
14. launchDate
15. launchUnixTime
16. active
17. hidden
18. finishedLaunching
19. ownsMenuBar

Changed files:
- `Sources/ProcAppInfo/AppInfo.swift` — struct fields reordered, group comments added
- `Sources/ProcAppInfo/ProcessUtils.swift` — `makeAppInfo` initializer arguments reordered
- `Sources/proc-appinfo/ProcAppInfo.swift` — `@Flag` declarations, `selectedFields`, `output()`, `humanOutput()` reordered; `.sortedKeys` removed from JSON encoder so JSON follows struct order
- `README.md` — sample output block and single-field flags list reordered

---

## Skipped (revisit later)

### Perspective 2: Force unwraps in `jsonOutput`

```swift
let data = try! encoder.encode(info)
return String(data: data, encoding: .utf8)!
```

Both force unwraps are safe — `AppInfo` only contains standard `Codable` types so encoding cannot fail, and `JSONEncoder` always produces valid UTF-8. Key discussion points:
- `try?` + fallback produces silent empty output on failure (worse than a crash)
- `try!` crashes loudly on violated invariant (honest)
- Making the call chain `throws` adds complexity for an error that can't occur
- Left as-is for now pending decision on whether any change is warranted

---

## Todo

### Perspective 3: Nil vs empty string in single-field mode

When a field flag is used (e.g. `--bundle-name`) and the field is nil, output is `""`.
Scripts cannot distinguish nil from empty string. Tool exits 0 in both cases.
- `ProcAppInfo.swift:97-118`

### Perspective 4: Redundant derived fields in `AppInfo`

`architectureName` and `activationPolicyName` are stored fields but are purely derived from the raw Int fields via static helpers. Could be computed properties, removing the redundancy.
- `AppInfo.swift:15-21`, `ProcessUtils.swift:80-81`

### Perspective 5: `--from-pid` validation

No guard against 0 or negative PIDs. Invalid PID silently throws a generic "not found" error with no hint that the user-supplied PID was the problem.
- `ProcAppInfo.swift:82-90`, `ProcessUtils.swift:27-35`

### Perspective 6: Test coverage

Zero tests. Core logic in `findAppInfo` is DI-friendly and ready for unit tests. Key scenarios: found on first try, found after N hops, stops at PID 1, cycle guard, nil parent breaks loop.
- `ProcessUtils.swift:22-36`

### Perspective 7: Feature completeness

- No `--all` mode to list all ancestor apps
- `--from-pid` walks from that PID itself, not its parent (potentially surprising, undocumented)
- No granular exit codes beyond 0/1
- `launchDate` always uses local timezone

### Perspective 8: Swift conventions

- `@usableFromInline` on `parentPID` and `makeAppInfo` without `@inlinable` is a no-op — should just be `internal`
- Static helpers `architectureName(_:)` and `activationPolicyName(_:)` on the model are unconventional

### Perspective 9: Human readability

- `selectedFields` is an unlabelled Bool array — easy to get out of sync with `output()`
- `output()` if-chain grows fragile at scale
- Label strings in `humanOutput()` duplicate `@Flag` help text with no cross-check
