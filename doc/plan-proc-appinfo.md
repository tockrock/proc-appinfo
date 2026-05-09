# Plan: Rename to `proc-appinfo` + Expand Output Fields

## Context

`terminal-bundleid` was built to find the bundle ID of the terminal app that
launched the current process. The name and scope are both too narrow:

- Not all callers are terminal scripts — any process can use it
- It only returns the bundle ID; the underlying `NSRunningApplication` object
  exposes many more useful fields
- The name should reflect that it discovers the current app context without
  exposing the process-walking mechanism to the user

The new name is `proc-appinfo`. The tool returns all available fields from
`NSRunningApplication` by default, with flags to narrow to a single field.
Interface follows the `sw_vers` pattern.

---

## Critical Files

| File | Change |
|------|--------|
| `Package.swift` | Rename all targets |
| `Sources/TerminalBundleID/ProcessUtils.swift` | Rename + expand → `Sources/ProcAppInfo/ProcessUtils.swift` |
| `Sources/terminal-bundleid/TerminalBundleID.swift` | Replace wholesale → `Sources/proc-appinfo/ProcAppInfo.swift` |
| `Tests/TerminalBundleIDTests/ProcessUtilsTests.swift` | Update imports + assertions → `Tests/ProcAppInfoTests/ProcessUtilsTests.swift` |

---

## CLI Interface (sw_vers model)

```
# Default — all fields, human-readable
$ proc-appinfo
Name:                iTerm2
Bundle ID:           com.googlecode.iterm2
PID:                 832
Bundle Path:         /Applications/iTerm2.app
Executable Path:     /Applications/iTerm2.app/Contents/MacOS/iTerm2
Version:             3.4.19
Architecture:        arm64
Launch Date:         2024-03-14T13:46:57Z
Active:              false
Hidden:              false
Finished Launching:  true
Owns Menu Bar:       false
Activation Policy:   regular

# Single field — plain value only (for scripting)
$ proc-appinfo --bundleid
com.googlecode.iterm2

# All fields as JSON
$ proc-appinfo --json

# Walk from a specific PID (renamed from --pid to avoid conflict with --pid field flag)
$ proc-appinfo --from-pid 1234
```

**Multiple field flags combined** → ArgumentParser rejects automatically (mutual
exclusivity is free when multiple `@Flag` cases map to the same stored property).

**`--json` + field flag combined** → rejected in `validate()` with a clear error.

**Nil fields** → omitted from human output; emitted as `null` in JSON; print
empty string in single-field mode.

---

## Step 1: Rename Directories

```bash
git mv Sources/TerminalBundleID Sources/ProcAppInfo
git mv Sources/terminal-bundleid Sources/proc-appinfo
git mv Tests/TerminalBundleIDTests Tests/ProcAppInfoTests
```

## Step 2: Update `Package.swift`

- `name:` → `"proc-appinfo"`
- Library target `"TerminalBundleID"` → `"ProcAppInfo"`
- Executable target `"terminal-bundleid"` → `"proc-appinfo"`, dependency updated
- Test target `"TerminalBundleIDTests"` → `"ProcAppInfoTests"`, dependency updated

## Step 3: Library — `Sources/ProcAppInfo/ProcessUtils.swift`

### New `AppInfo` struct

Split into `AppInfo.swift` or keep in `ProcessUtils.swift`:

```swift
public struct AppInfo: Equatable, Codable {
    public let name: String?
    public let bundleId: String?
    public let pid: Int32
    public let bundlePath: String?
    public let executablePath: String?
    public let version: String?          // from Info.plist CFBundleShortVersionString
    public let launchDate: Date?
    public let active: Bool
    public let hidden: Bool
    public let finishedLaunching: Bool
    public let ownsMenuBar: Bool
    public let activationPolicy: ActivationPolicy
    public let architecture: Architecture

    public enum ActivationPolicy: String, Codable, Equatable {
        case regular, accessory, prohibited
    }
    public enum Architecture: String, Codable, Equatable {
        case arm64, x86_64, unknown
    }
}
```

### Rename error type

```swift
public enum ProcAppInfoError: LocalizedError {
    case appNotFound
    public var errorDescription: String? {
        "Could not find a registered macOS app in the process ancestry chain."
    }
}
```

### Rename + update main function

- `findTerminalBundleID` → `findAppInfo`, returns `AppInfo` instead of `String`
- Third injection parameter: `bundleIDFor: (pid_t) -> String?` → `appFor: (pid_t) -> AppInfo?`
- Throws `ProcAppInfoError.appNotFound`

### Add private `makeAppInfo(pid:)` helper

Wraps `NSRunningApplication`. Reads `version` from
`Bundle(url: bundleURL)?.infoDictionary?["CFBundleShortVersionString"]`.
Maps `executableArchitecture` integer → `.arm64` / `.x86_64` / `.unknown`.
Maps `activationPolicy` enum → `ActivationPolicy` cases.

## Step 4: CLI Entry Point — `Sources/proc-appinfo/ProcAppInfo.swift`

### `FieldName` enum

```swift
enum FieldName: String, EnumerableFlag, CaseIterable {
    case name, bundleid, pid
    case bundlePath, executablePath, version, launchDate
    case active, hidden, finishedLaunching, ownsMenuBar
    case activationPolicy, architecture
}
```

Override `name(for:)` to force `--bundleid` (not auto-kebab'd to `--bundle-id`).

### Command struct

```swift
@main struct ProcAppInfo: ParsableCommand {
    @Option(name: .customLong("from-pid"), help: "Walk ancestors of this PID.")
    var fromPid: Int32?

    @Flag(help: "Output a single field value.")
    var field: FieldName? = nil

    @Flag(name: .long, help: "Output all fields as JSON.")
    var json: Bool = false

    mutating func validate() throws {
        if field != nil && json {
            throw ValidationError("Field flags and --json are mutually exclusive.")
        }
    }

    mutating func run() throws {
        let info = try findAppInfo(startingFrom: fromPid)
        if let field { print(singleValue(info, field: field)) }
        else if json  { print(jsonOutput(info)) }
        else          { print(humanOutput(info)) }
    }
}
```

### Output helpers

- `humanOutput(_:)` — aligned key-value pairs, skipping nil fields
- `singleValue(_:field:)` — plain string for the requested field
- `jsonOutput(_:)` — `JSONEncoder` with `.prettyPrinted`, `.iso8601` date strategy

**Note on `--pid` conflict:** Renamed to `--from-pid` because `--pid` (no value)
is needed as a field selection flag, while `--from-pid <n>` (takes a value) sets
the starting process.

## Step 5: Update Tests — `Tests/ProcAppInfoTests/ProcessUtilsTests.swift`

- `@testable import TerminalBundleID` → `@testable import ProcAppInfo`
- `makeTree` helper: `apps: [pid_t: String]` → `apps: [pid_t: AppInfo]`
- Add `stubApp(bundleId:pid:)` factory for minimal test stubs
- Assertions: `result == "com.apple.Terminal"` → `result.bundleId == "com.apple.Terminal"`
- `CLIError.terminalNotFound` → `ProcAppInfoError.appNotFound`
- `findTerminalBundleID(...)` → `findAppInfo(...)`
- Preserve all 6 existing test cases; update signatures only

---

## Verification

```bash
# Build
swift build

# Run default output
swift run proc-appinfo

# Single field
swift run proc-appinfo --bundleid
swift run proc-appinfo --name

# JSON
swift run proc-appinfo --json

# From specific PID
swift run proc-appinfo --from-pid <pid>

# Mutual exclusivity checks (should error)
swift run proc-appinfo --name --bundleid
swift run proc-appinfo --name --json

# Tests
swift test
```
