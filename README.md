# proc-appinfo

A macOS CLI tool that returns information about the first ancestor macOS app in the current process tree — typically the terminal or app that launched the process.

```
$ proc-appinfo
Bundle Name:            Terminal
Bundle Display Name:    Terminal
Localized Name:         ターミナル
Bundle ID:              com.apple.Terminal
Version:                2.15
Build Version:          470
PID:                    812
Architecture:           16777228
Architecture Name:      arm64
Activation Policy:      0
Activation Policy Name: regular
Bundle Path:            /System/Applications/Utilities/Terminal.app
Executable Path:        /System/Applications/Utilities/Terminal.app/Contents/MacOS/Terminal
Launch Date:            2026-04-13T09:24:41+0900
Launch Unix Time:       1776039881.557612
Active:                 true
Hidden:                 false
Finished Launching:     true
Owns Menu Bar:          true
```

## How it works

`proc-appinfo` walks the process ancestry tree using `sysctl`. Starting from its own parent process, it checks each ancestor against `NSRunningApplication` until it finds the first registered app bundle.

## Installation

### Homebrew

```bash
brew tap tockrock/tap
brew install tockrock/tap/proc-appinfo
```

### Build from source

```bash
git clone https://github.com/tockrock/terminal-bundleid
cd terminal-bundleid
swift build -c release
cp .build/release/proc-appinfo /usr/local/bin/
```

## Usage

```bash
# All fields, human-readable
proc-appinfo

# Single field (for scripting)
proc-appinfo --bundle-name
proc-appinfo --bundle-display-name
proc-appinfo --localized-name
proc-appinfo --bundle-id
proc-appinfo --version
proc-appinfo --build-version
proc-appinfo --pid
proc-appinfo --architecture
proc-appinfo --architecture-name
proc-appinfo --activation-policy
proc-appinfo --activation-policy-name
proc-appinfo --bundle-path
proc-appinfo --executable-path
proc-appinfo --launch-date
proc-appinfo --launch-unix-time
proc-appinfo --active
proc-appinfo --hidden
proc-appinfo --finished-launching
proc-appinfo --owns-menu-bar

# All fields as JSON
proc-appinfo --json

# Walk ancestors of a specific PID
proc-appinfo --from-pid 1234
```

### Scripting

Single-field flags print a plain value to stdout with no extra formatting:

```bash
open -b "$(proc-appinfo --bundle-id)"
```
