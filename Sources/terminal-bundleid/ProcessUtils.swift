import Darwin
import AppKit

/// Errors thrown during terminal bundle ID resolution.
enum CLIError: LocalizedError {
    /// No app bundle was found in the process ancestry chain.
    case terminalNotFound

    var errorDescription: String? {
        "Could not determine the terminal app's bundle ID."
    }
}

/// Returns the parent PID of the given process using `proc_pidinfo`.
///
/// - Parameter pid: The process ID to query.
/// - Returns: The parent PID, or `nil` if the process doesn't exist or has no parent.
func parentPID(of pid: pid_t) -> pid_t? {
    var info = proc_bsdinfo()
    let size = Int32(MemoryLayout<proc_bsdinfo>.size)
    guard proc_pidinfo(pid, PROC_PIDTBSDINFO, 0, &info, size) > 0 else { return nil }
    let ppid = info.pbi_ppid
    return ppid > 0 ? pid_t(ppid) : nil
}

/// Walks the process ancestry tree and returns the bundle ID of the first
/// ancestor that is a registered macOS app bundle.
///
/// - Throws: ``CLIError/terminalNotFound`` if no app bundle is found before reaching PID 1.
/// - Returns: The bundle identifier string (e.g. `com.apple.Terminal`).
func findTerminalBundleID() throws -> String {
    var pid = getppid()
    while pid > 1 {
        if let app = NSRunningApplication(processIdentifier: pid),
           let bundleID = app.bundleIdentifier {
            return bundleID
        }
        guard let parent = parentPID(of: pid), parent != pid else { break }
        pid = parent
    }
    throw CLIError.terminalNotFound
}
