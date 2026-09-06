import Foundation
import SwiftUI

public enum ServiceCategory: String, CaseIterable, Codable, Identifiable, Sendable {
    case all = "All"
    case systemUI = "System UI"
    case audio = "Audio & Media"
    case networking = "Networking"
    case system = "System & Utilities"
    case custom = "Custom"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .all:
            return "square.grid.2x2"
        case .systemUI:
            return "macwindow"
        case .audio:
            return "speaker.wave.3.fill"
        case .networking:
            return "network"
        case .system:
            return "gearshape.2.fill"
        case .custom:
            return "wrench.and.screwdriver"
        }
    }
    
    public var accentColor: Color {
        switch self {
        case .all:
            return .primary
        case .systemUI:
            return .blue
        case .audio:
            return .purple
        case .networking:
            return .cyan
        case .system:
            return .orange
        case .custom:
            return .green
        }
    }
}
