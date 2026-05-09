# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Build
swift build

# Build release
swift build -c release

# Run
swift run proc-appinfo

# Test (no tests currently exist)
swift test
```

## Documentation

- `doc/plan.md` — original implementation plan and design decisions
- `doc/adr-sysctl-vs-proc_pidinfo.md` — why `sysctl` was chosen over `proc_pidinfo`

## Architecture

`proc-appinfo` is a Swift Package (macOS 13+) CLI tool with three source files:

- **`Sources/proc-appinfo/ProcAppInfo.swift`** — Entry point. Uses `swift-argument-parser` (`ParsableCommand`) to define the CLI and output formatting.
- **`Sources/ProcAppInfo/AppInfo.swift`** — `AppInfo` struct with all fields returned by the tool.
- **`Sources/ProcAppInfo/ProcessUtils.swift`** — Core logic. Walks the process ancestry tree via `sysctl` (`KERN_PROC_PID`) to get parent PIDs, then checks each ancestor against `NSRunningApplication` to find the first registered app bundle.

The tool exits with a non-zero code if no ancestor app bundle is found.

**Key constraint:** Must run as a macOS app-context process (not sandboxed) because it uses `NSRunningApplication` from AppKit, which requires access to the window server / running applications list.
