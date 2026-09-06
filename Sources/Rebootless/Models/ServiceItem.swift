import Foundation

public struct ServiceItem: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public var name: String
    public var subtitle: String
    public var category: ServiceCategory
    public var iconName: String
    public var fixesDescription: String
    public var keywords: [String]
    public var command: String
    public var requiresAdmin: Bool
    public var isDangerous: Bool
    public var warningMessage: String?
    public var isBuiltIn: Bool
    public var isFavorited: Bool
    
    public init(
        id: String,
        name: String,
        subtitle: String,
        category: ServiceCategory,
        iconName: String,
        fixesDescription: String,
        keywords: [String] = [],
        command: String,
        requiresAdmin: Bool = false,
        isDangerous: Bool = false,
        warningMessage: String? = nil,
        isBuiltIn: Bool = true,
        isFavorited: Bool = false
    ) {
        self.id = id
        self.name = name
        self.subtitle = subtitle
        self.category = category
        self.iconName = iconName
        self.fixesDescription = fixesDescription
        self.keywords = keywords
        self.command = command
        self.requiresAdmin = requiresAdmin
        self.isDangerous = isDangerous
        self.warningMessage = warningMessage
        self.isBuiltIn = isBuiltIn
        self.isFavorited = isFavorited
    }
}

extension ServiceItem {
    public static let builtInServices: [ServiceItem] = [
        // MARK: - System UI
        ServiceItem(
            id: "finder",
            name: "Finder",
            subtitle: "Desktop & File Manager",
            category: .systemUI,
            iconName: "macwindow",
            fixesDescription: "Fixes frozen desktop, stuck file moves/copies, broken folder views, unresponsive file open/save dialogs.",
            keywords: ["finder", "desktop", "files", "folder", "copy", "dialog", "frozen", "trash", "hang"],
            command: "killall Finder",
            requiresAdmin: false,
            isBuiltIn: true,
            isFavorited: true
        ),
        ServiceItem(
            id: "dock",
            name: "Dock & Mission Control",
            subtitle: "App Dock, Stage Manager & Spaces",
            category: .systemUI,
            iconName: "dock.rectangle",
            fixesDescription: "Fixes hidden or unresponsive Dock, stuck app badges, Mission Control lag, Stage Manager window glitches.",
            keywords: ["dock", "mission control", "stage manager", "spaces", "badges", "launchpad", "stuck icon"],
            command: "killall Dock",
            requiresAdmin: false,
            isBuiltIn: true,
            isFavorited: true
        ),
        ServiceItem(
            id: "systemuiserver",
            name: "Menu Bar & Control Center",
            subtitle: "SystemUIServer & Menu Extras",
            category: .systemUI,
            iconName: "menubar.rectangle",
            fixesDescription: "Fixes frozen menu bar items, clock not updating, stuck Wi-Fi/Battery menu icons, unresponsive Control Center toggles.",
            keywords: ["menu bar", "clock", "battery", "control center", "systemuiserver", "status item", "icons"],
            command: "killall SystemUIServer",
            requiresAdmin: false,
            isBuiltIn: true,
            isFavorited: false
        ),
        ServiceItem(
            id: "notificationcenter",
            name: "Notification Center",
            subtitle: "Alerts, Banners & Widgets",
            category: .systemUI,
            iconName: "bell.badge",
            fixesDescription: "Fixes stuck alert banners that won't dismiss, unresponsive notification widgets, delayed or missing alerts.",
            keywords: ["notification", "banner", "alerts", "widgets", "sounds", "dismiss"],
            command: "killall NotificationCenter",
            requiresAdmin: false,
            isBuiltIn: true,
            isFavorited: false
        ),
        ServiceItem(
            id: "quicklook",
            name: "Quick Look Previews",
            subtitle: "Spacebar File Preview Engine",
            category: .systemUI,
            iconName: "eye.circle",
            fixesDescription: "Fixes spacebar preview failing to open images, PDFs, videos, code files, or showing blank windows.",
            keywords: ["quick look", "preview", "spacebar", "thumbnails", "generator", "pdf", "image"],
            command: "qlmanage -r && qlmanage -r cache",
            requiresAdmin: false,
            isBuiltIn: true,
            isFavorited: false
        ),
        ServiceItem(
            id: "wallpaper",
            name: "Wallpaper Agent",
            subtitle: "Desktop Backgrounds & Dynamic Wallpapers",
            category: .systemUI,
            iconName: "photo.artframe",
            fixesDescription: "Fixes black desktop screen, frozen dynamic wallpapers, or multi-display wallpaper synchronization glitches.",
            keywords: ["wallpaper", "background", "black screen", "desktop image", "dynamic wallpaper", "screensaver"],
            command: "killall WallpaperAgent 2>/dev/null || killall Wallpaper 2>/dev/null || true",
            requiresAdmin: false,
            isBuiltIn: true,
            isFavorited: false
        ),
        ServiceItem(
            id: "touchbar",
            name: "Touch Bar & Control Strip",
            subtitle: "Touch Bar Agent (MacBook Pro)",
            category: .systemUI,
            iconName: "rectangle.bottomthird.inset.filled",
            fixesDescription: "Fixes frozen, black, or unresponsive Touch Bar controls and Fn key bar on supported MacBooks.",
            keywords: ["touch bar", "control strip", "fn keys", "touchbar", "macbook pro", "brightness slider"],
            command: "pkill 'Touch Bar agent' 2>/dev/null || true; killall ControlStrip 2>/dev/null || true",
            requiresAdmin: false,
            isBuiltIn: true,
            isFavorited: false
        ),

        // MARK: - Audio & Media
        ServiceItem(
            id: "coreaudio",
            name: "Core Audio (Sound)",
            subtitle: "System Audio & Microphone Daemon",
            category: .audio,
            iconName: "speaker.wave.3.fill",
            fixesDescription: "Fixes sound cutouts, crackling audio, AirPods not playing sound, input mic not detected or stuck.",
            keywords: ["sound", "audio", "coreaudio", "volume", "speakers", "airpods", "headphones", "microphone", "mic", "crackling", "mute", "glitch"],
            command: "launchctl kickstart -kp system/com.apple.audio.coreaudiod 2>/dev/null || killall -9 coreaudiod",
            requiresAdmin: true,
            isBuiltIn: true,
            isFavorited: true
        ),
        ServiceItem(
            id: "airplay",
            name: "AirPlay & Sidecar",
            subtitle: "Wireless Display & Audio Streaming",
            category: .audio,
            iconName: "airplayvideo",
            fixesDescription: "Fixes screen mirroring disconnects, iPad Sidecar failure, or Apple TV stream freezing.",
            keywords: ["airplay", "sidecar", "mirroring", "apple tv", "screen share", "ipad display"],
            command: "killall AirPlayXPCHelper 2>/dev/null || true",
            requiresAdmin: false,
            isBuiltIn: true,
            isFavorited: false
        ),

        // MARK: - Networking
        ServiceItem(
            id: "dnscache",
            name: "DNS Cache",
            subtitle: "Domain Name Resolution Cache",
            category: .networking,
            iconName: "network",
            fixesDescription: "Fixes websites not loading after DNS/VPN changes, local domain lookup failures, or stale cache.",
            keywords: ["dns", "cache", "domain", "internet", "website", "vpn", "lookup", "resolve", "flush"],
            command: "dscacheutil -flushcache && killall -HUP mDNSResponder 2>/dev/null || true",
            requiresAdmin: false,
            isBuiltIn: true,
            isFavorited: true
        ),
        ServiceItem(
            id: "bluetooth",
            name: "Bluetooth Subsystem",
            subtitle: "Bluetooth Daemon & Peripheral Controller",
            category: .networking,
            iconName: "antenna.radiowaves.left.and.right",
            fixesDescription: "Fixes unresponsive Bluetooth devices, wireless headphones dropping connection, or keyboard/mouse stutter.",
            keywords: ["bluetooth", "airpods", "magic mouse", "keyboard", "headphones", "pairing", "disconnect", "stutter"],
            command: "pkill -9 bluetoothd",
            requiresAdmin: true,
            isBuiltIn: true,
            isFavorited: false
        ),
        ServiceItem(
            id: "wifi",
            name: "Wi-Fi Interface",
            subtitle: "Airport Network Adapter Reset",
            category: .networking,
            iconName: "wifi",
            fixesDescription: "Fixes self-assigned IP address (169.254), Wi-Fi connection drops, or endless 'Connecting...' status.",
            keywords: ["wifi", "wi-fi", "wireless", "airport", "ip address", "dhcp", "no internet", "disconnect"],
            command: "WIFI_DEV=$(networksetup -listallhardwareports | awk '/Hardware Port: Wi-Fi/{getline; print $2}'); if [ -n \"$WIFI_DEV\" ]; then networksetup -setairportpower \"$WIFI_DEV\" off && sleep 1 && networksetup -setairportpower \"$WIFI_DEV\" on; fi",
            requiresAdmin: false,
            isBuiltIn: true,
            isFavorited: true
        ),
        ServiceItem(
            id: "airdrop",
            name: "AirDrop & Bonjour",
            subtitle: "mDNSResponder Local Network Discovery",
            category: .networking,
            iconName: "person.wave.2.fill",
            fixesDescription: "Fixes AirDrop failing to discover contacts/devices, local network printers offline, and .local host resolution.",
            keywords: ["airdrop", "bonjour", "mdnsresponder", "discovery", "printers", "local network", "sharing"],
            command: "killall -9 mDNSResponder",
            requiresAdmin: true,
            isBuiltIn: true,
            isFavorited: false
        ),

        // MARK: - System & Utilities
        ServiceItem(
            id: "spotlight",
            name: "Spotlight Indexer",
            subtitle: "Metadata Indexing (mds & mds_stores)",
            category: .system,
            iconName: "magnifyingglass",
            fixesDescription: "Fixes Spotlight search returning blank/delayed results, files not indexed, or runaway CPU usage.",
            keywords: ["spotlight", "search", "indexing", "mds", "mds_stores", "cpu", "find files"],
            command: "killall mds 2>/dev/null || true; killall mds_stores 2>/dev/null || true",
            requiresAdmin: false,
            isBuiltIn: true,
            isFavorited: false
        ),
        ServiceItem(
            id: "siri",
            name: "Siri & Dictation",
            subtitle: "Voice Assistant & Speech Recognition",
            category: .system,
            iconName: "mic.fill",
            fixesDescription: "Fixes Siri failing to activate, dictation hanging on listening, or orange microphone indicator staying stuck.",
            keywords: ["siri", "dictation", "speech", "microphone icon", "voice", "hey siri"],
            command: "killall Siri 2>/dev/null || true; killall com.apple.siri.embeddedspeech 2>/dev/null || true",
            requiresAdmin: false,
            isBuiltIn: true,
            isFavorited: false
        ),
        ServiceItem(
            id: "timemachine",
            name: "Time Machine Engine",
            subtitle: "Backup Daemon (backupd)",
            category: .system,
            iconName: "clock.arrow.circlepath",
            fixesDescription: "Cancels and resets backups stuck in 'Preparing backup...', hung disk verification, or frozen external drive.",
            keywords: ["time machine", "backup", "backupd", "preparing backup", "external drive", "stuck"],
            command: "killall backupd 2>/dev/null || true",
            requiresAdmin: false,
            isBuiltIn: true,
            isFavorited: false
        ),
        ServiceItem(
            id: "printspool",
            name: "Print Spooler",
            subtitle: "CUPS Printing System Queue",
            category: .system,
            iconName: "printer.fill",
            fixesDescription: "Cancels hung print jobs that block the printer queue and restores offline printer communication.",
            keywords: ["printer", "cups", "print", "queue", "spooler", "paper", "hung job"],
            command: "cancel -a 2>/dev/null || true",
            requiresAdmin: false,
            isBuiltIn: true,
            isFavorited: false
        ),

        // MARK: - Advanced / Dangerous
        ServiceItem(
            id: "windowserver",
            name: "WindowServer (Session Reset)",
            subtitle: "macOS Display Compositor & Window Manager",
            category: .systemUI,
            iconName: "exclamationmark.triangle.fill",
            fixesDescription: "Emergency graphics reset for total visual lockups or frozen display drivers. ⚠️ Logs out your current user session!",
            keywords: ["windowserver", "graphics", "gpu", "frozen screen", "display", "lockup", "crash", "logout"],
            command: "killall -HUP WindowServer",
            requiresAdmin: true,
            isDangerous: true,
            warningMessage: "Warning: Restarting WindowServer will immediately terminate all running graphical applications and log you out to the login screen. Any unsaved work will be lost.",
            isBuiltIn: true,
            isFavorited: false
        )
    ]
}
