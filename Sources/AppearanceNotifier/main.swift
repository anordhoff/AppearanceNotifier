import AppKit
import Foundation
import ShellOut

private let kAppleInterfaceThemeChangedNotification = "AppleInterfaceThemeChangedNotification"

enum Theme: String {
    case Light, Dark
}

class DarkModeObserver {
    func observe() {
        print("Observing")

        DistributedNotificationCenter.default.addObserver(
            forName: Notification.Name(kAppleInterfaceThemeChangedNotification),
            object: nil,
            queue: nil,
            using: interfaceModeChanged(notification:)
        )
    }

    func interfaceModeChanged(notification _: Notification) {
        let styleRaw = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") ?? "Light"
        let style = Theme(rawValue: styleRaw)!

        print("\(Date()) Theme changed: \(style)")

        do {
            let output = try shellOut(to: "nvr", arguments: ["--serverlist"])
            let servers = output.split(whereSeparator: \.isNewline)

            if servers.isEmpty {
                print("\(Date()) no servers")
            } else {
                servers.forEach { server in
                    let server = String(server)

                    print("\(Date()) server \(server): sending command")

                    let arguments = build_nvim_background_arguments(server: server, theme: style)

                    DispatchQueue.global().async {
                        do {
                            try shellOut(to: "nvr", arguments: arguments)
                        } catch {
                            print("\(Date()) server \(String(server)): command failed")
                        }
                    }
                }
            }

            switch style {
            case .Light:
                DispatchQueue.global().async {
                    print("\(Date()) kitty: sending command")

                    let arguments = build_kitty_arguments(theme: "/Users/jesse/.config/kitty/colours/sainnhe/edge/edge-light.conf")

                    do {
                        try shellOut(to: "kitty", arguments: arguments)
                    } catch {
                        print("\(Date()) kitty: command failed")
                    }
                }
            case .Dark:
                DispatchQueue.global().async {
                    print("\(Date()) kitty: sending command")

                    let arguments = build_kitty_arguments(theme: "/Users/jesse/.config/kitty/colours/sainnhe/edge/edge-dark.conf")

                    do {
                        try shellOut(to: "kitty", arguments: arguments)
                    } catch {
                        print("\(Date()) kitty: command failed")
                    }
                }
            }
        } catch {
            let error = error as! ShellOutError
            print(error.message) // Prints STDERR
            print(error.output) // Prints STDOUT
        }
    }
}

func build_nvim_background_arguments(server: String, theme: Theme) -> [String] {
    return ["--servername", server, "+'set background=\(theme.rawValue.lowercased())'"]
}

func build_kitty_arguments(theme: String) -> [String] {
    return [
        "@", "--to", "unix:/tmp/kitty", "set-colors", "--all", "--configured", theme,
    ]
}

let app = NSApplication.shared

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_: Notification) {
        let observer = DarkModeObserver()
        observer.observe()
    }
}

let delegate = AppDelegate()
app.delegate = delegate
app.run()
