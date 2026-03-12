import Testing
import Darwin
@testable import TerminalBundleID

// Helpers for building fake process trees in tests.
// `parents` maps pid -> parent pid; `apps` maps pid -> bundle ID.
private func makeTree(
    parents: [pid_t: pid_t],
    apps: [pid_t: String]
) -> (parentOf: (pid_t) -> pid_t?, bundleIDFor: (pid_t) -> String?) {
    ({ parents[$0] }, { apps[$0] })
}

@Suite("findTerminalBundleID")
struct FindTerminalBundleIDTests {

    @Test("returns bundle ID of direct parent app")
    func directParent() throws {
        // 200 -> 100 (app)
        let (parentOf, bundleIDFor) = makeTree(
            parents: [200: 100],
            apps: [100: "com.apple.Terminal"]
        )
        let result = try findTerminalBundleID(startingFrom: 200, parentOf: parentOf, bundleIDFor: bundleIDFor)
        #expect(result == "com.apple.Terminal")
    }

    @Test("walks multiple levels to find the app")
    func multipleHops() throws {
        // 500 -> 400 -> 300 -> 200 (app)
        let (parentOf, bundleIDFor) = makeTree(
            parents: [500: 400, 400: 300, 300: 200],
            apps: [200: "com.googlecode.iterm2"]
        )
        let result = try findTerminalBundleID(startingFrom: 500, parentOf: parentOf, bundleIDFor: bundleIDFor)
        #expect(result == "com.googlecode.iterm2")
    }

    @Test("throws terminalNotFound when no app is in the chain")
    func notFound() {
        // 300 -> 200 -> 100 -> nil, no apps
        let (parentOf, bundleIDFor) = makeTree(
            parents: [300: 200, 200: 100],
            apps: [:]
        )
        #expect(throws: CLIError.terminalNotFound) {
            try findTerminalBundleID(startingFrom: 300, parentOf: parentOf, bundleIDFor: bundleIDFor)
        }
    }

    @Test("stops at PID 1 and throws")
    func stopsAtPIDOne() {
        // Chain reaches PID 1, which the loop condition excludes
        let (parentOf, bundleIDFor) = makeTree(
            parents: [200: 1],
            apps: [:]
        )
        #expect(throws: CLIError.terminalNotFound) {
            try findTerminalBundleID(startingFrom: 200, parentOf: parentOf, bundleIDFor: bundleIDFor)
        }
    }

    @Test("breaks on cycle (parent == self)")
    func cycleBreak() {
        let (_, bundleIDFor) = makeTree(parents: [:], apps: [:])
        // parentOf always returns the same PID — simulates a cycle
        #expect(throws: CLIError.terminalNotFound) {
            try findTerminalBundleID(startingFrom: 50, parentOf: { $0 }, bundleIDFor: bundleIDFor)
        }
    }

    @Test("breaks when parentOf returns nil")
    func parentNil() {
        let (_, bundleIDFor) = makeTree(parents: [:], apps: [:])
        #expect(throws: CLIError.terminalNotFound) {
            try findTerminalBundleID(startingFrom: 99, parentOf: { _ in nil }, bundleIDFor: bundleIDFor)
        }
    }

    @Test("returns first app found, not deepest")
    func returnsNearest() throws {
        // 400 -> 300 (app) -> 200 (also an app)
        let (parentOf, bundleIDFor) = makeTree(
            parents: [400: 300, 300: 200],
            apps: [300: "com.nearest.App", 200: "com.far.App"]
        )
        let result = try findTerminalBundleID(startingFrom: 400, parentOf: parentOf, bundleIDFor: bundleIDFor)
        #expect(result == "com.nearest.App")
    }
}
