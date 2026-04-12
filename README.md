# proc-appinfo

A macOS CLI tool that returns information about the first ancestor macOS app in the current process tree — typically the terminal or app that launched the process.

```
$ proc-appinfo
Bundle Name:          Terminal
Bundle Display Name:  Terminal
Localized Name:       ターミナル
Bundle ID:            com.apple.Terminal
PID:                  812
Bundle Path:          /System/Applications/Utilities/Terminal.app
Executable Path:      /System/Applications/Utilities/Terminal.app/Contents/MacOS/Terminal
Version:              2.15
Build Version:        470
Architecture:         16777228
Launch Date:          2026-04-12T01:34:41Z
Active:               true
Hidden:               false
Finished Launching:   true
Owns Menu Bar:        true
Activation Policy:    0
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
proc-appinfo --pid
proc-appinfo --version
proc-appinfo --build-version
proc-appinfo --bundle-path
proc-appinfo --executable-path
proc-appinfo --launch-date
proc-appinfo --active
proc-appinfo --hidden
proc-appinfo --finished-launching
proc-appinfo --owns-menu-bar
proc-appinfo --activation-policy
proc-appinfo --architecture

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
