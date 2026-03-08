# terminal-bundleid — Implementation Plan

## Goal

A Swift CLI tool that dynamically returns the macOS bundle ID of the terminal
app you are currently running it from.

## Approach

1. **Walk the process ancestry tree** using Darwin's `sysctl` with
   `KERN_PROC_PID` to traverse from the current process upward.

2. **Resolve the bundle ID** by checking each ancestor PID against
   `NSRunningApplication(processIdentifier:)` — the first match is the
   terminal app.

## File Structure

```
terminal-bundleid/
├── PLAN.md                                 ← this file
├── Package.swift
└── Sources/
    └── terminal-bundleid/
        ├── TerminalBundleID.swift          # @main ParsableCommand
        └── ProcessUtils.swift              # sysctl helpers + CLIError
```

## Dependencies

| Package | URL | Version |
|---------|-----|---------|
| swift-argument-parser | https://github.com/apple/swift-argument-parser | ≥ 1.3.0 |

Platform: **macOS 15+**

## CLI Interface

```
USAGE: terminal-bundleid

OPTIONS:
  -h, --help      Show help information.
```

### Examples

```bash
$ terminal-bundleid
com.mitchellh.ghostty
```

## Key Implementation Details

### ProcessUtils.swift

**`parentPID(of:) -> pid_t?`**
```swift
var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, pid]
var info = kinfo_proc()
var size = MemoryLayout<kinfo_proc>.size
sysctl(&mib, 4, &info, &size, nil, 0)
return info.kp_eproc.e_ppid
```

**`findTerminalBundleID() throws -> String`**
```
start at getppid()
while pid > 1:
    if NSRunningApplication(pid).bundleIdentifier exists → return it
    pid = parentPID(pid)
throw CLIError.terminalNotFound
```

## Build & Verify

```bash
swift build
swift run terminal-bundleid

# Release install
swift build -c release
cp .build/release/terminal-bundleid /usr/local/bin/
```
