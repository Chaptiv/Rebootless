import SwiftUI

public struct CustomServiceSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var serviceManager: ServiceManager
    
    @State private var name: String = ""
    @State private var subtitle: String = ""
    @State private var command: String = ""
    @State private var fixesDescription: String = ""
    @State private var iconName: String = "wrench.and.screwdriver"
    @State private var requiresAdmin: Bool = false
    @State private var isFavorited: Bool = true
    
    private let availableIcons = [
        "wrench.and.screwdriver", "gearshape.2.fill", "server.rack",
        "terminal.fill", "shippingbox.fill", "cpu", "bolt.fill",
        "waveform.path.ecg", "arrow.trianglehead.2.clockwise.rotate.90",
        "display", "network", "lock.shield.fill"
    ]
    
    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !command.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Add Custom Service")
                    .font(.system(size: 16, weight: .bold))
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            Divider()
            
            // Form
            Form {
                Section("Service Details") {
                    TextField("Name (e.g. Docker Desktop)", text: $name)
                    TextField("Subtitle (e.g. Container Runtime)", text: $subtitle)
                    TextField("Problem it fixes", text: $fixesDescription)
                }
                
                Section("Execution") {
                    TextField("Shell Command (e.g. killall Docker && open -a Docker)", text: $command)
                        .font(.system(size: 12, design: .monospaced))
                    
                    Toggle("Requires Administrator / Root Privileges (Touch ID)", isOn: $requiresAdmin)
                    Toggle("Add to Menu Bar Favorites immediately", isOn: $isFavorited)
                }
                
                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 8) {
                        ForEach(availableIcons, id: \.self) { icon in
                            Button {
                                iconName = icon
                            } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(iconName == icon ? Color.accentColor : Color.primary.opacity(0.06))
                                        .frame(width: 36, height: 36)
                                    Image(systemName: icon)
                                        .foregroundColor(iconName == icon ? .white : .primary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .formStyle(.grouped)
            
            Divider()
            
            // Footer
            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Add Service") {
                    let newService = ServiceItem(
                        id: "custom_\(UUID().uuidString.prefix(8))",
                        name: name.trimmingCharacters(in: .whitespaces),
                        subtitle: subtitle.isEmpty ? "Custom Service" : subtitle.trimmingCharacters(in: .whitespaces),
                        category: .custom,
                        iconName: iconName,
                        fixesDescription: fixesDescription.isEmpty ? "Custom restart command." : fixesDescription,
                        keywords: [name.lowercased(), subtitle.lowercased()],
                        command: command.trimmingCharacters(in: .whitespaces),
                        requiresAdmin: requiresAdmin,
                        isDangerous: false,
                        isBuiltIn: false,
                        isFavorited: isFavorited
                    )
                    serviceManager.addCustomService(newService)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValid)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .frame(width: 480, height: 480)
    }
}
