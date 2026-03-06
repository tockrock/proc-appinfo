import ArgumentParser
import AppKit

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
