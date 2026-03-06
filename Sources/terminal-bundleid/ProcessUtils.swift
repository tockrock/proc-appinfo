import Darwin
import AppKit

enum CLIError: LocalizedError {
    case terminalNotFound

    var errorDescription: String? {
        "Could not determine the terminal app's bundle ID."
    }
}

func parentPID(of pid: pid_t) -> pid_t? {
    var info = proc_bsdinfo()
    let size = Int32(MemoryLayout<proc_bsdinfo>.size)
    guard proc_pidinfo(pid, PROC_PIDTBSDINFO, 0, &info, size) > 0 else { return nil }
    let ppid = info.pbi_ppid
    return ppid > 0 ? pid_t(ppid) : nil
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
