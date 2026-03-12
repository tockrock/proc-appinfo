import Darwin
import AppKit

/// Errors thrown during terminal bundle ID resolution.
public enum CLIError: LocalizedError {
    /// No app bundle was found in the process ancestry chain.
    case terminalNotFound

    public var errorDescription: String? {
        "Could not determine the terminal app's bundle ID."
    }
}

/// Returns the parent PID of the given process using `sysctl`.
///
/// - Parameter pid: The process ID to query.
/// - Returns: The parent PID, or `nil` if the process doesn't exist or has no parent.
public func parentPID(of pid: pid_t) -> pid_t? {
    var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, pid]
    var info = kinfo_proc()
    var size = MemoryLayout<kinfo_proc>.size
    guard sysctl(&mib, 4, &info, &size, nil, 0) == 0, size > 0 else { return nil }
    let ppid = info.kp_eproc.e_ppid
    return ppid > 0 ? ppid : nil
}

/// Walks the process ancestry tree and returns the bundle ID of the first
/// ancestor that is a registered macOS app bundle.
///
/// - Parameters:
///   - startPID: The PID to start from. Defaults to `getppid()`.
///   - parentOf: Returns the parent PID for a given PID. Defaults to the real `sysctl` lookup.
///   - bundleIDFor: Returns the bundle ID for a given PID, or `nil` if it isn't a registered app.
/// - Throws: ``CLIError/terminalNotFound`` if no app bundle is found before reaching PID 1.
/// - Returns: The bundle identifier string (e.g. `com.apple.Terminal`).
public func findTerminalBundleID(
    startingFrom startPID: pid_t? = nil,
    parentOf: (pid_t) -> pid_t? = { parentPID(of: $0) },
    bundleIDFor: (pid_t) -> String? = { NSRunningApplication(processIdentifier: $0)?.bundleIdentifier }
) throws -> String {
    var pid = startPID ?? getppid()
    while pid > 1 {
        if let bundleID = bundleIDFor(pid) {
            return bundleID
        }
        guard let parent = parentOf(pid), parent != pid else { break }
        pid = parent
    }
    throw CLIError.terminalNotFound
}
