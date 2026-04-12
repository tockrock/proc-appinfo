import Darwin
import AppKit

/// Errors thrown during app info resolution.
public enum ProcAppInfoError: LocalizedError {
    case appNotFound

    public var errorDescription: String? {
        "Could not find a registered macOS app in the process ancestry chain."
    }
}

/// Walks the process ancestry tree and returns app info for the first
/// ancestor that is a registered macOS app bundle.
///
/// - Parameters:
///   - startPID: The PID to start from. Defaults to `getppid()`.
///   - parentOf: Returns the parent PID for a given PID.
///   - appFor: Returns an `AppInfo` for a given PID, or `nil` if not a registered app.
/// - Throws: ``ProcAppInfoError/appNotFound`` if no app bundle is found before reaching PID 1.
/// - Returns: An `AppInfo` describing the first ancestor app.
public func findAppInfo(
    startingFrom startPID: pid_t? = nil,
    parentOf: (pid_t) -> pid_t? = { parentPID(of: $0) },
    appFor: (pid_t) -> AppInfo? = { makeAppInfo(pid: $0) }
) throws -> AppInfo {
    var pid = startPID ?? getppid()
    while pid > 1 {
        if let info = appFor(pid) {
            return info
        }
        guard let parent = parentOf(pid), parent != pid else { break }
        pid = parent
    }
    throw ProcAppInfoError.appNotFound
}

/// Returns the parent PID of the given process using `sysctl`.
///
/// - Parameter pid: The process ID to query.
/// - Returns: The parent PID, or `nil` if the process doesn't exist or has no parent.
@usableFromInline
func parentPID(of pid: pid_t) -> pid_t? {
    var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, pid]
    var info = kinfo_proc()
    var size = MemoryLayout<kinfo_proc>.size
    guard sysctl(&mib, 4, &info, &size, nil, 0) == 0, size > 0 else { return nil }
    let ppid = info.kp_eproc.e_ppid
    return ppid > 0 ? ppid : nil
}

/// Builds an `AppInfo` from `NSRunningApplication` for the given PID.
/// Returns `nil` if the PID is not a registered macOS app.
@usableFromInline
func makeAppInfo(pid: pid_t) -> AppInfo? {
    guard let app = NSRunningApplication(processIdentifier: pid) else { return nil }

    let bundleURL = app.bundleURL
    let bundle = bundleURL.flatMap { Bundle(url: $0) }
    let version = bundle?.infoDictionary?["CFBundleShortVersionString"] as? String
    let buildVersion = bundle?.infoDictionary?["CFBundleVersion"] as? String
    let bundleName = bundle?.infoDictionary?["CFBundleName"] as? String
    let bundleDisplayName = bundle?.infoDictionary?["CFBundleDisplayName"] as? String

    return AppInfo(
        bundleName: bundleName,
        bundleDisplayName: bundleDisplayName,
        localizedName: app.localizedName,
        bundleId: app.bundleIdentifier,
        pid: pid,
        bundlePath: bundleURL?.path,
        executablePath: app.executableURL?.path,
        version: version,
        buildVersion: buildVersion,
        launchDate: app.launchDate,
        active: app.isActive,
        hidden: app.isHidden,
        finishedLaunching: app.isFinishedLaunching,
        ownsMenuBar: app.ownsMenuBar,
        activationPolicy: app.activationPolicy.rawValue,
        architecture: app.executableArchitecture
    )
}
