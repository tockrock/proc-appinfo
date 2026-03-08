# terminal-bundleid

A macOS CLI tool that returns the bundle ID of the terminal app you are currently running it from.

```bash
$ terminal-bundleid
com.apple.Terminal
```

## How it works

`terminal-bundleid` dynamically walks the process ancestry tree using `sysctl`. Starting from its own parent process, it checks each ancestor against `NSRunningApplication` until it finds the first registered app bundle — which is the terminal.

## Installation

### Homebrew

```bash
brew tap tockrock/terminal-bundleid
brew install terminal-bundleid
```

### Build from source

```bash
git clone https://github.com/tockrock/terminal-bundleid
cd terminal-bundleid
swift build -c release
cp .build/release/terminal-bundleid /usr/local/bin/
```

## Usage

```bash
terminal-bundleid
```

Prints the bundle ID of the current terminal app to stdout and exits. Non-zero exit code on failure.

### Scripting

The output is plain stdout, making it easy to compose with other tools:

```bash
BUNDLE_ID=$(terminal-bundleid)
defaults read "$BUNDLE_ID" AppleLanguages
```
