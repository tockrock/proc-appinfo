import ArgumentParser
import AppKit

/// The root command. Resolves the bundle ID of the terminal app that
/// launched this process and prints it to stdout.
@main
struct TerminalBundleID: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "terminal-bundleid",
        abstract: "Returns the macOS bundle ID of the current terminal app."
    )

    mutating func run() throws {
        let bundleID = try findTerminalBundleID()
        print(bundleID)
    }
}
