# Rebootless ⚡️
> **One-click macOS subsystem & service restarter right from your Menu Bar.** Fix frozen apps, sound glitches, Wi-Fi drops, and desktop hangs without Terminal commands or full system reboots.

---

## 💡 Why Rebootless?

macOS is reliable, but over days and weeks of heavy use, background services can get stuck:
- **CoreAudio** glitches out, mic stops working, or AirPods won't output sound.
- **Finder** hangs during a file copy or open/save dialog.
- **Dock** hides itself, or Mission Control stutters.
- **DNS Cache** refuses to resolve websites after a VPN disconnect.
- **Quick Look** spacebar previews show a blank screen.
- **AirDrop** fails to find contacts or nearby Macs.

Most users either endure a frustrating full Mac reboot or need to remember obscure Terminal commands like `sudo killall coreaudiod` or `dscacheutil -flushcache`.

**Rebootless solves this with one click.** It stays quietly in your Menu Bar as a sleek icon. Click it to restart your favorited services immediately, or open the Dashboard to browse services, use the Troubleshooter, or add your own custom commands.

---

## ✨ Features

- **Discrete Menu Bar Utility**: Stays out of your way on the right side of the macOS Menu Bar.
- **1-Click Favorite Restarts**: Star your most-used services to restart them directly from the Menu Bar dropdown with animated live feedback (spinner ➔ checkmark).
- **Restart All Favorites**: One button to refresh all your pinned services at once.
- **Interactive "Fix My Problem" Troubleshooter**: Describe your symptom in plain English ("Sound is crackling", "Desktop frozen", "Spacebar previews blank") and let Rebootless trigger the exact underlying macOS daemon fix.
- **Comprehensive Built-In Catalog**: 18+ preconfigured system services across UI, Audio, Networking, Hardware, and Utilities.
- **Custom Services**: Add your own shell scripts and commands (e.g., Docker Desktop, Tailscale, local web servers) with custom icons and admin privileges.
- **Technical Disclosure**: Expand any service card to view and copy the exact shell command being executed.
- **History & Diagnostic Logs**: Review past restart events, execution duration in milliseconds, exit codes, and output streams.
- **Native macOS Experience**: Built with 100% Swift and SwiftUI, supporting Dark/Light mode, SF Symbols, system notifications, and `SMAppService` launch-at-login.

---

## 🛠 Built-in Services Catalog

| Category | Service | What Problem It Solves | Command Executed | Elevated? |
|---|---|---|---|:---:|
| **System UI** | **Finder** | Frozen desktop, stuck file transfers, broken folder views, hung open/save dialogs | `killall Finder` | No |
| **System UI** | **Dock & Mission Control** | Missing Dock, stuck app icon badges, Mission Control stutter, Stage Manager glitches | `killall Dock` | No |
| **System UI** | **Menu Bar & Control Center** | Frozen clock, stuck menu bar icons, unresponsive Control Center toggles | `killall SystemUIServer` | No |
| **System UI** | **Notification Center** | Stuck notification banners, unresponsive notification widgets | `killall NotificationCenter` | No |
| **System UI** | **Quick Look Previews** | Spacebar preview not showing images, PDFs, videos, or code files | `qlmanage -r && qlmanage -r cache` | No |
| **System UI** | **Wallpaper Agent** | Black desktop background, frozen dynamic wallpapers | `killall WallpaperAgent` | No |
| **System UI** | **Touch Bar & Control Strip** | Frozen or black Touch Bar on supported MacBook Pro models | `pkill "Touch Bar agent"; killall ControlStrip` | No |
| **Audio & Media** | **Core Audio (Sound)** | No sound, crackling audio, AirPods not playing sound, input mic not detected | `launchctl kickstart -kp ... \|\| killall -9 coreaudiod` | Yes (Touch ID) |
| **Audio & Media** | **AirPlay & Sidecar** | Screen mirroring dropouts, iPad Sidecar connection failure | `killall AirPlayXPCHelper` | No |
| **Networking** | **DNS Cache** | Websites not loading after VPN/router changes, local hostname lookup fail | `dscacheutil -flushcache && killall -HUP mDNSResponder` | No |
| **Networking** | **Bluetooth Subsystem** | Unresponsive Bluetooth devices, wireless headphone dropouts, mouse stutter | `pkill -9 bluetoothd` | Yes (Touch ID) |
| **Networking** | **Wi-Fi Interface** | Self-assigned IP (169.254.x.x), stuck connecting, network connection drops | `networksetup -setairportpower ... off/on` | No |
| **Networking** | **AirDrop & Bonjour** | AirDrop failing to discover contacts, offline network printers, `.local` domains | `killall -9 mDNSResponder` | Yes (Touch ID) |
| **System** | **Spotlight Indexer** | Search returning blank results, files not indexed, runaway CPU indexing | `killall mds; killall mds_stores` | No |
| **System** | **Siri & Dictation** | Voice dictation hanging, Siri not responding, mic indicator stuck orange | `killall Siri; killall com.apple.siri.embeddedspeech` | No |
| **System** | **Time Machine Engine** | Backup hanging on 'Preparing backup...', stuck disk verification | `killall backupd` | No |
| **System** | **Print Spooler** | Hung print jobs blocking the printer queue | `cancel -a` | No |
| **Advanced** | **WindowServer** | Emergency graphics reset for total visual lockups (⚠️ logs out user session) | `killall -HUP WindowServer` | Yes |

---

## 🚀 Getting Started

### Requirements
- macOS 14.0 (Sonoma) or newer (including macOS Sequoia / macOS 26).
- Apple Silicon or Intel Mac.

### Building & Running
You can compile and package the app in a single step using the included build script:

```bash
# Clone or navigate to the repository
cd rebootless

# Build the release .app bundle
./build_app.sh

# Launch Rebootless
open Rebootless.app
```

### Installing into Applications
To make Rebootless permanently available in your Applications folder:
```bash
cp -R Rebootless.app /Applications/
```

You can also run it directly in developer mode via Swift Package Manager:
```bash
swift run
```

---

## 🧪 Running Unit Tests

Rebootless includes a test suite covering model integrity, catalog mappings, serialization, and command execution:

```bash
swift test
```

---

## 🔒 Security & Privileges

- Services that operate in user space (Finder, Dock, Quick Look, DNS cache flush, etc.) execute directly as your standard user with zero administrative prompts.
- Subsystem daemons that require elevated root permissions (such as `coreaudiod` or `bluetoothd`) use standard AppleScript elevation, cleanly triggering macOS's native Touch ID or Administrator Password prompt. Rebootless never stores or asks for passwords directly.
- High-impact actions like `WindowServer` (which resets the display session and logs you out) feature safety confirmations enabled by default.

---

## 📄 License
MIT License. Feel free to use, modify, and contribute.
