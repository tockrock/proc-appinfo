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
    @Flag(help: "Print the app name.") var name: Bool = false
    @Flag(help: "Print the bundle identifier.") var bundleId: Bool = false
    @Flag(help: "Print the process ID.") var pid: Bool = false
    @Flag(help: "Print the bundle path.") var bundlePath: Bool = false
    @Flag(help: "Print the executable path.") var executablePath: Bool = false
    @Flag(help: "Print the version.") var version: Bool = false
    @Flag(help: "Print the launch date (ISO 8601).") var launchDate: Bool = false
    @Flag(help: "Print whether the app is active.") var active: Bool = false
    @Flag(help: "Print whether the app is hidden.") var hidden: Bool = false
    @Flag(help: "Print whether the app has finished launching.") var finishedLaunching: Bool = false
    @Flag(help: "Print whether the app owns the menu bar.") var ownsMenuBar: Bool = false
    @Flag(help: "Print the activation policy.") var activationPolicy: Bool = false
    @Flag(help: "Print the executable architecture.") var architecture: Bool = false

    @Flag(help: "Output all fields as a JSON object.") var json: Bool = false

    private var selectedFields: [Bool] {
        [name, bundleId, pid, bundlePath, executablePath, version, launchDate,
         active, hidden, finishedLaunching, ownsMenuBar, activationPolicy, architecture]
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
        let info = try findAppInfo(startingFrom: fromPid)
        if json {
            print(jsonOutput(info))
        } else if name              { print(info.name ?? "") }
        else if bundleId            { print(info.bundleId ?? "") }
        else if pid                 { print(info.pid) }
        else if bundlePath          { print(info.bundlePath ?? "") }
        else if executablePath      { print(info.executablePath ?? "") }
        else if version             { print(info.version ?? "") }
        else if launchDate          { print(info.launchDate.map { ISO8601DateFormatter().string(from: $0) } ?? "") }
        else if active              { print(info.active) }
        else if hidden              { print(info.hidden) }
        else if finishedLaunching   { print(info.finishedLaunching) }
        else if ownsMenuBar         { print(info.ownsMenuBar) }
        else if activationPolicy    { print(info.activationPolicy) }
        else if architecture        { print(info.architecture) }
        else                        { print(humanOutput(info)) }
    }
}

// MARK: - Output formatting

private func humanOutput(_ info: AppInfo) -> String {
    var lines: [(String, String)] = []
    if let v = info.name            { lines.append(("Name:", v)) }
    if let v = info.bundleId        { lines.append(("Bundle ID:", v)) }
    lines.append(("PID:", String(info.pid)))
    if let v = info.bundlePath      { lines.append(("Bundle Path:", v)) }
    if let v = info.executablePath  { lines.append(("Executable Path:", v)) }
    if let v = info.version         { lines.append(("Version:", v)) }
    lines.append(("Architecture:", String(info.architecture)))
    if let v = info.launchDate      { lines.append(("Launch Date:", ISO8601DateFormatter().string(from: v))) }
    lines.append(("Active:", String(info.active)))
    lines.append(("Hidden:", String(info.hidden)))
    lines.append(("Finished Launching:", String(info.finishedLaunching)))
    lines.append(("Owns Menu Bar:", String(info.ownsMenuBar)))
    lines.append(("Activation Policy:", String(info.activationPolicy)))

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
