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
    public let launchUnixTime: Double?
    public let active: Bool
    public let hidden: Bool
    public let finishedLaunching: Bool
    public let ownsMenuBar: Bool
    public let activationPolicy: Int
    public let activationPolicyName: String
    public let architecture: Int
    public let architectureName: String

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
