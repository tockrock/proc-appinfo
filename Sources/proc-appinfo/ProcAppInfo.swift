import ArgumentParser
import Foundation
import ProcAppInfo

@main
struct AppInfoCLI: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "proc-appinfo",
        abstract: "Shows information about the first ancestor macOS app of a process."
    )

    @Option(help: "Walk ancestors of this PID instead of the current process.")
    var fromPid: Int32?

    // Single-field selection flags (sw_vers style — mutually exclusive)
    @Flag(help: "Print the bundle name (CFBundleName).")
    var bundleName: Bool = false

    @Flag(help: "Print the bundle display name (CFBundleDisplayName).")
    var bundleDisplayName: Bool = false

    @Flag(help: "Print the localized app name.")
    var localizedName: Bool = false

    @Flag(help: "Print the bundle identifier.")
    var bundleId: Bool = false

    @Flag(help: "Print the process ID.")
    var pid: Bool = false

    @Flag(help: "Print the bundle path.")
    var bundlePath: Bool = false

    @Flag(help: "Print the executable path.")
    var executablePath: Bool = false

    @Flag(help: "Print the version.")
    var version: Bool = false

    @Flag(help: "Print the build version (CFBundleVersion).")
    var buildVersion: Bool = false

    @Flag(help: "Print the launch date (ISO 8601, local timezone).")
    var launchDate: Bool = false

    @Flag(help: "Print the launch date as Unix time (seconds since epoch).")
    var launchUnixTime: Bool = false

    @Flag(help: "Print whether the app is active.")
    var active: Bool = false

    @Flag(help: "Print whether the app is hidden.")
    var hidden: Bool = false

    @Flag(help: "Print whether the app has finished launching.")
    var finishedLaunching: Bool = false

    @Flag(help: "Print whether the app owns the menu bar.")
    var ownsMenuBar: Bool = false

    @Flag(help: "Print the activation policy.")
    var activationPolicy: Bool = false

    @Flag(help: "Print the activation policy as a human-readable string.")
    var activationPolicyName: Bool = false

    @Flag(help: "Print the executable architecture.")
    var architecture: Bool = false

    @Flag(help: "Print the executable architecture as a human-readable string.")
    var architectureName: Bool = false

    @Flag(help: "Output all fields as a JSON object.")
    var json: Bool = false

    private var selectedFields: [Bool] {
        [bundleName, bundleDisplayName, localizedName, bundleId, pid, bundlePath, executablePath, version, buildVersion,
         launchDate, launchUnixTime, active, hidden, finishedLaunching, ownsMenuBar,
         activationPolicy, activationPolicyName, architecture, architectureName]
    }

    mutating func validate() throws {
        let count = selectedFields.filter { $0 }.count
        if count > 1 {
            throw ValidationError("Only one field flag may be specified at a time. Use --json for multiple fields.")
        }
        if count == 1 && json {
            throw ValidationError("Field flags and --json are mutually exclusive.")
        }
    }

    mutating func run() throws {
        let appInfo = try findAppInfo(startingFrom: fromPid)
        print(output(appInfo))
    }

    private func output(_ appInfo: AppInfo) -> String {
        if json                 { return jsonOutput(appInfo) }
        if bundleName           { return appInfo.bundleName ?? "" }
        if bundleDisplayName    { return appInfo.bundleDisplayName ?? "" }
        if localizedName        { return appInfo.localizedName ?? "" }
        if bundleId             { return appInfo.bundleId ?? "" }
        if pid                  { return String(appInfo.pid) }
        if bundlePath           { return appInfo.bundlePath ?? "" }
        if executablePath       { return appInfo.executablePath ?? "" }
        if version              { return appInfo.version ?? "" }
        if buildVersion         { return appInfo.buildVersion ?? "" }
        if launchDate           { return appInfo.launchDate?.formatted(.localTime) ?? "" }
        if launchUnixTime       { return appInfo.launchUnixTime.map { String($0) } ?? "" }
        if active               { return String(appInfo.active) }
        if hidden               { return String(appInfo.hidden) }
        if finishedLaunching    { return String(appInfo.finishedLaunching) }
        if ownsMenuBar          { return String(appInfo.ownsMenuBar) }
        if activationPolicy     { return String(appInfo.activationPolicy) }
        if activationPolicyName { return appInfo.activationPolicyName }
        if architecture         { return String(appInfo.architecture) }
        if architectureName     { return appInfo.architectureName }
        return humanOutput(appInfo)
    }
}

// MARK: - Output formatting

private func humanOutput(_ info: AppInfo) -> String {
    var lines: [(String, String)] = []
    lines.append(("Bundle Name:", info.bundleName ?? ""))
    lines.append(("Bundle Display Name:", info.bundleDisplayName ?? ""))
    lines.append(("Localized Name:", info.localizedName ?? ""))
    lines.append(("Bundle ID:", info.bundleId ?? ""))
    lines.append(("PID:", String(info.pid)))
    lines.append(("Bundle Path:", info.bundlePath ?? ""))
    lines.append(("Executable Path:", info.executablePath ?? ""))
    lines.append(("Version:", info.version ?? ""))
    lines.append(("Build Version:", info.buildVersion ?? ""))
    lines.append(("Architecture:", String(info.architecture)))
    lines.append(("Architecture Name:", info.architectureName))
    lines.append(("Launch Date:", info.launchDate?.formatted(.localTime) ?? ""))
    lines.append(("Launch Unix Time:", info.launchUnixTime.map { String($0) } ?? ""))
    lines.append(("Active:", String(info.active)))
    lines.append(("Hidden:", String(info.hidden)))
    lines.append(("Finished Launching:", String(info.finishedLaunching)))
    lines.append(("Owns Menu Bar:", String(info.ownsMenuBar)))
    lines.append(("Activation Policy:", String(info.activationPolicy)))
    lines.append(("Activation Policy Name:", info.activationPolicyName))

    let maxLen = lines.map { $0.0.count }.max() ?? 0
    return lines.map { label, value in
        label.padding(toLength: maxLen + 2, withPad: " ", startingAt: 0) + value
    }.joined(separator: "\n")
}

private func jsonOutput(_ info: AppInfo) -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    encoder.dateEncodingStrategy = .iso8601
    let data = try! encoder.encode(info)
    return String(data: data, encoding: .utf8)!
}

// MARK: - Extensions

private extension FormatStyle where Self == Date.ISO8601FormatStyle {
    static var localTime: Self { Date.ISO8601FormatStyle(timeZone: .current) }
}
