import Foundation

public struct TroubleshootItem: Identifiable, Sendable {
    public let id: String
    public let title: String
    public let symptom: String
    public let iconName: String
    public let serviceId: String
    public let recommendedActionTitle: String
    
    public init(
        id: String,
        title: String,
        symptom: String,
        iconName: String,
        serviceId: String,
        recommendedActionTitle: String
    ) {
        self.id = id
        self.title = title
        self.symptom = symptom
        self.iconName = iconName
        self.serviceId = serviceId
        self.recommendedActionTitle = recommendedActionTitle
    }
}

extension TroubleshootItem {
    public static let commonIssues: [TroubleshootItem] = [
        TroubleshootItem(
            id: "issue_sound",
            title: "Sound, Headphones & Mic",
            symptom: "No sound output, crackling noise, mic not detected, or AirPods won't connect.",
            iconName: "speaker.wave.3.fill",
            serviceId: "coreaudio",
            recommendedActionTitle: "Restart Core Audio"
        ),
        TroubleshootItem(
            id: "issue_finder",
            title: "Desktop & Files Frozen",
            symptom: "Finder is not responding, file move/copy is frozen, or open/save dialogs hang.",
            iconName: "macwindow",
            serviceId: "finder",
            recommendedActionTitle: "Restart Finder"
        ),
        TroubleshootItem(
            id: "issue_dock",
            title: "Dock & Stage Manager Glitches",
            symptom: "Dock disappeared, app icon badges are stuck, or Mission Control is lagging.",
            iconName: "dock.rectangle",
            serviceId: "dock",
            recommendedActionTitle: "Restart Dock"
        ),
        TroubleshootItem(
            id: "issue_quicklook",
            title: "Spacebar File Previews",
            symptom: "Pressing Spacebar on an image, PDF or file shows a blank or loading box.",
            iconName: "eye.circle",
            serviceId: "quicklook",
            recommendedActionTitle: "Restart Quick Look"
        ),
        TroubleshootItem(
            id: "issue_wifi",
            title: "Wi-Fi Stuck or Self-Assigned IP",
            symptom: "Wi-Fi is stuck on 'Looking for Networks', drops connection, or shows self-assigned IP.",
            iconName: "wifi",
            serviceId: "wifi",
            recommendedActionTitle: "Cycle Wi-Fi Adapter"
        ),
        TroubleshootItem(
            id: "issue_dns",
            title: "Websites Won't Load",
            symptom: "Internet is connected but specific websites won't open after VPN or router changes.",
            iconName: "network",
            serviceId: "dnscache",
            recommendedActionTitle: "Flush DNS Cache"
        ),
        TroubleshootItem(
            id: "issue_bluetooth",
            title: "Bluetooth Devices Disconnecting",
            symptom: "Bluetooth mouse lags, AirPods disconnect randomly, or new devices won't pair.",
            iconName: "antenna.radiowaves.left.and.right",
            serviceId: "bluetooth",
            recommendedActionTitle: "Restart Bluetooth Daemon"
        ),
        TroubleshootItem(
            id: "issue_airdrop",
            title: "AirDrop Not Finding Devices",
            symptom: "Your Mac doesn't show up on iPhone or other Macs, or network printers are offline.",
            iconName: "person.wave.2.fill",
            serviceId: "airdrop",
            recommendedActionTitle: "Restart AirDrop / Bonjour"
        ),
        TroubleshootItem(
            id: "issue_menubar",
            title: "Menu Bar Clock or Icons Frozen",
            symptom: "Menu bar clock stopped advancing, battery icon stuck, or Control Center won't open.",
            iconName: "menubar.rectangle",
            serviceId: "systemuiserver",
            recommendedActionTitle: "Restart SystemUIServer"
        ),
        TroubleshootItem(
            id: "issue_notifications",
            title: "Notification Banners Stuck",
            symptom: "A notification banner won't swipe away or notification sound repeats endlessly.",
            iconName: "bell.badge",
            serviceId: "notificationcenter",
            recommendedActionTitle: "Restart Notification Center"
        ),
        TroubleshootItem(
            id: "issue_wallpaper",
            title: "Desktop Screen is Black",
            symptom: "Wallpaper turned black, dynamic wallpapers stopped moving, or second display has no wallpaper.",
            iconName: "photo.artframe",
            serviceId: "wallpaper",
            recommendedActionTitle: "Restart Wallpaper Agent"
        ),
        TroubleshootItem(
            id: "issue_spotlight",
            title: "Spotlight Search Returns Nothing",
            symptom: "Cmd+Space search is slow, missing files, or high CPU usage from indexing.",
            iconName: "magnifyingglass",
            serviceId: "spotlight",
            recommendedActionTitle: "Restart Spotlight"
        )
    ]
}
