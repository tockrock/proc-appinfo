import Foundation

/// Information about a running macOS application, sourced from NSRunningApplication.
public struct AppInfo: Equatable, Codable {
    // Identity
    public let bundleName: String?
    public let bundleDisplayName: String?
    public let localizedName: String?
    public let bundleId: String?

    // Version
    public let version: String?
    public let buildVersion: String?

    // Process
    public let pid: Int32
    public let architecture: Int
    public let architectureName: String
    public let activationPolicy: Int
    public let activationPolicyName: String

    // Paths
    public let bundlePath: String?
    public let executablePath: String?

    // Runtime state
    public let launchDate: Date?
    public let launchUnixTime: Double?
    public let active: Bool
    public let hidden: Bool
    public let finishedLaunching: Bool
    public let ownsMenuBar: Bool

    public static func architectureName(_ raw: Int) -> String {
        switch raw {
        case NSBundleExecutableArchitectureI386:   "i386"
        case NSBundleExecutableArchitectureX86_64: "x86_64"
        case NSBundleExecutableArchitectureARM64:  "arm64"
        case NSBundleExecutableArchitecturePPC:    "ppc"
        case NSBundleExecutableArchitecturePPC64:  "ppc64"
        default:                                   "unknown(\(raw))"
        }
    }

    public static func activationPolicyName(_ raw: Int) -> String {
        switch raw {
        case 0:  "regular"
        case 1:  "accessory"
        case 2:  "prohibited"
        default: "unknown(\(raw))"
        }
    }
}
