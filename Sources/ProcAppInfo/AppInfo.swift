import Foundation

/// Information about a running macOS application, sourced from NSRunningApplication.
public struct AppInfo: Equatable, Codable {
    public let bundleName: String?
    public let bundleDisplayName: String?
    public let localizedName: String?
    public let bundleId: String?
    public let pid: Int32
    public let bundlePath: String?
    public let executablePath: String?
    public let version: String?
    public let buildVersion: String?
    public let launchDate: Date?
    public let active: Bool
    public let hidden: Bool
    public let finishedLaunching: Bool
    public let ownsMenuBar: Bool
    public let activationPolicy: Int
    public let architecture: Int
}
