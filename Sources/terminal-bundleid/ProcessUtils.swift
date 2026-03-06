import Darwin
import AppKit

enum CLIError: LocalizedError {
    case terminalNotFound

    var errorDescription: String? {
        "Could not determine the terminal app's bundle ID."
    }
}

func parentPID(of pid: pid_t) -> pid_t? {
    var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, pid]
    var info = kinfo_proc()
    var size = MemoryLayout<kinfo_proc>.size
    guard sysctl(&mib, 4, &info, &size, nil, 0) == 0, size > 0 else { return nil }
    let ppid = info.kp_eproc.e_ppid
    return ppid > 0 ? ppid : nil
}

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
