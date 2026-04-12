import Foundation

/// Information about a running macOS application, sourced from NSRunningApplication.
public struct AppInfo: Equatable, Codable {
    public let name: String?
    public let bundleId: String?
    public let pid: Int32
    public let bundlePath: String?
    public let executablePath: String?
    public let version: String?
    public let launchDate: Date?
    public let active: Bool
    public let hidden: Bool
    public let finishedLaunching: Bool
    public let ownsMenuBar: Bool
    public let activationPolicy: ActivationPolicy
    public let architecture: Architecture

    public enum ActivationPolicy: String, Codable, Equatable {
        case regular, accessory, prohibited
    }

    public enum Architecture: String, Codable, Equatable {
        case arm64, x86_64, unknown
    }
}
