import AppKit
import ShellOut

// kitty themes to switch between
let lightTheme = "gruvbox-light"
let darkTheme  = "gruvbox-dark"

private let kAppleInterfaceThemeChangedNotification = "AppleInterfaceThemeChangedNotification"

enum Theme {
    case light
    case dark
}

class ThemeChangeObserver {
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
        let themeRaw = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") ?? "Light"

        let theme = notificationToTheme(themeRaw: themeRaw)!

        notify(theme: theme)

        respond(theme: theme)
    }
}

func notificationToTheme(themeRaw: String) -> Theme? {
    return {
        switch themeRaw {
        case "Light":
            return Theme.light
        case "Dark":
            return Theme.dark
        default:
            return nil
        }
    }()
}

func notify(theme: Theme) {
    print("\(Date()) Theme changed: \(theme)")
}

func respond(theme: Theme) {
    DispatchQueue.global().async {
        print("\(Date()) kitty: sending command")

        let kittyArguments = buildKittyArguments(theme: theme)
        do {
            try shellOut(to: "/opt/homebrew/bin/kitty", arguments: kittyArguments)
        } catch {
            print("\(Date()) kitty: command failed")
        }

        let copyArguments = buildCopyArguments(theme: theme)
        do {
            try shellOut(to: "cp", arguments: copyArguments)
        } catch {
            print("\(Date()) cp: command failed")
        }
    }
}

func buildKittyArguments(theme: Theme) -> [String] {
    return [
        "kitten",
        "@",
        "--to",
        "unix:/tmp/mykitty",
        "set-colors",
        "--all",
        "~/.config/kitty/themes/\(getTheme(theme: theme)).conf",
    ]
}

func buildCopyArguments(theme: Theme) -> [String] {
    return [
        "~/.config/kitty/themes/\(getTheme(theme: theme)).conf",
        "~/.config/kitty/current-theme.conf",
    ]
}

func getTheme(theme: Theme) -> String {
    return {
        switch theme {
        case .light:
            return lightTheme
        case .dark:
            return darkTheme
        }
    }()
}

let app = NSApplication.shared

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_: Notification) {
        let observer = ThemeChangeObserver()
        observer.observe()
    }
}

let delegate = AppDelegate()
app.delegate = delegate
app.run()
