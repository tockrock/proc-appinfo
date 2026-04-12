import Testing
import Darwin
@testable import ProcAppInfo

// Minimal AppInfo stub for testing — only bundleId needs to be meaningful.
private func stubApp(bundleId: String, pid: pid_t = 100) -> AppInfo {
    AppInfo(
        name: nil,
        bundleId: bundleId,
        pid: pid,
        bundlePath: nil,
        executablePath: nil,
        version: nil,
        launchDate: nil,
        active: false,
        hidden: false,
        finishedLaunching: true,
        ownsMenuBar: false,
        activationPolicy: 0,
        architecture: 0
    )
}

// Helpers for building fake process trees in tests.
// `parents` maps pid -> parent pid; `apps` maps pid -> AppInfo.
private func makeTree(
    parents: [pid_t: pid_t],
    apps: [pid_t: AppInfo]
) -> (parentOf: (pid_t) -> pid_t?, appFor: (pid_t) -> AppInfo?) {
    ({ parents[$0] }, { apps[$0] })
}

@Suite("findAppInfo")
struct FindAppInfoTests {

    @Test("returns app info of direct parent app")
    func directParent() throws {
        // 200 -> 100 (app)
        let (parentOf, appFor) = makeTree(
            parents: [200: 100],
            apps: [100: stubApp(bundleId: "com.apple.Terminal", pid: 100)]
        )
        let result = try findAppInfo(startingFrom: 200, parentOf: parentOf, appFor: appFor)
        #expect(result.bundleId == "com.apple.Terminal")
    }

    @Test("walks multiple levels to find the app")
    func multipleHops() throws {
        // 500 -> 400 -> 300 -> 200 (app)
        let (parentOf, appFor) = makeTree(
            parents: [500: 400, 400: 300, 300: 200],
            apps: [200: stubApp(bundleId: "com.googlecode.iterm2", pid: 200)]
        )
        let result = try findAppInfo(startingFrom: 500, parentOf: parentOf, appFor: appFor)
        #expect(result.bundleId == "com.googlecode.iterm2")
    }

    @Test("throws appNotFound when no app is in the chain")
    func notFound() {
        // 300 -> 200 -> 100 -> nil, no apps
        let (parentOf, appFor) = makeTree(
            parents: [300: 200, 200: 100],
            apps: [:]
        )
        #expect(throws: ProcAppInfoError.appNotFound) {
            try findAppInfo(startingFrom: 300, parentOf: parentOf, appFor: appFor)
        }
    }

    @Test("stops at PID 1 and throws")
    func stopsAtPIDOne() {
        // Chain reaches PID 1, which the loop condition excludes
        let (parentOf, appFor) = makeTree(
            parents: [200: 1],
            apps: [:]
        )
        #expect(throws: ProcAppInfoError.appNotFound) {
            try findAppInfo(startingFrom: 200, parentOf: parentOf, appFor: appFor)
        }
    }

    @Test("breaks on cycle (parent == self)")
    func cycleBreak() {
        let (_, appFor) = makeTree(parents: [:], apps: [:])
        // parentOf always returns the same PID — simulates a cycle
        #expect(throws: ProcAppInfoError.appNotFound) {
            try findAppInfo(startingFrom: 50, parentOf: { $0 }, appFor: appFor)
        }
    }

    @Test("breaks when parentOf returns nil")
    func parentNil() {
        let (_, appFor) = makeTree(parents: [:], apps: [:])
        #expect(throws: ProcAppInfoError.appNotFound) {
            try findAppInfo(startingFrom: 99, parentOf: { _ in nil }, appFor: appFor)
        }
    }

    @Test("returns first app found, not deepest")
    func returnsNearest() throws {
        // 400 -> 300 (app) -> 200 (also an app)
        let (parentOf, appFor) = makeTree(
            parents: [400: 300, 300: 200],
            apps: [
                300: stubApp(bundleId: "com.nearest.App", pid: 300),
                200: stubApp(bundleId: "com.far.App", pid: 200),
            ]
        )
        let result = try findAppInfo(startingFrom: 400, parentOf: parentOf, appFor: appFor)
        #expect(result.bundleId == "com.nearest.App")
    }
}
