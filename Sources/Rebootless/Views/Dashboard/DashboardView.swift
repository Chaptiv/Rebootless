import SwiftUI

public enum DashboardTab: String, CaseIterable, Identifiable {
    case services = "All Services"
    case troubleshooter = "Fix My Problem"
    case custom = "Custom Services"
    case history = "History"
    case settings = "Settings"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .services:
            return "square.grid.2x2"
        case .troubleshooter:
            return "wand.and.stars"
        case .custom:
            return "wrench.and.screwdriver"
        case .history:
            return "clock.arrow.circlepath"
        case .settings:
            return "gearshape"
        }
    }
}

public struct DashboardView: View {
    @EnvironmentObject var serviceManager: ServiceManager
    @State private var selectedTab: DashboardTab = .services
    @State private var showingAddCustomSheet = false
    
    public init() {}
    
    public var body: some View {
        NavigationSplitView {
            List(DashboardTab.allCases, selection: $selectedTab) { tab in
                NavigationLink(value: tab) {
                    Label {
                        Text(tab.rawValue)
                            .font(.system(size: 13, weight: .medium))
                    } icon: {
                        Image(systemName: tab.icon)
                            .font(.system(size: 13))
                            .foregroundColor(.accentColor)
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 190, ideal: 210, max: 250)
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 8) {
                    Divider()
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Rebootless")
                                .font(.system(size: 12, weight: .bold))
                            Text("\(serviceManager.services.count) Services Active")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        
                        Button {
                            showingAddCustomSheet = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.accentColor)
                        }
                        .buttonStyle(.plain)
                        .help("Add Custom Service")
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 10)
                }
            }
        } detail: {
            Group {
                switch selectedTab {
                case .services:
                    ServiceListView()
                case .troubleshooter:
                    TroubleshootView()
                case .custom:
                    CustomServicesListView(showingAddSheet: $showingAddCustomSheet)
                case .history:
                    HistoryView()
                case .settings:
                    SettingsView()
                }
            }
            .navigationTitle(selectedTab.rawValue)
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    if selectedTab == .services || selectedTab == .custom {
                        Button {
                            showingAddCustomSheet = true
                        } label: {
                            Label("Add Service", systemImage: "plus")
                        }
                    }
                    
                    if !serviceManager.favoriteServices.isEmpty {
                        Button {
                            Task {
                                await serviceManager.restartAllFavorites()
                            }
                        } label: {
                            Label("Restart All Favorites", systemImage: "arrow.trianglehead.2.clockwise.rotate.90")
                        }
                        .disabled(serviceManager.isAnyRestarting)
                        .help("Restart all favorited services")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddCustomSheet) {
            CustomServiceSheet()
        }
        .frame(minWidth: 780, minHeight: 520)
    }
}

private struct CustomServicesListView: View {
    @EnvironmentObject var serviceManager: ServiceManager
    @Binding var showingAddSheet: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Custom Services")
                        .font(.system(size: 16, weight: .bold))
                    Text("Manage user-defined shell scripts and service restart commands")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button {
                    showingAddSheet = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Add Custom Service")
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(Color(nsColor: .windowBackgroundColor))
            
            Divider()
            
            if serviceManager.customServices.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "wrench.and.screwdriver")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary)
                    Text("No custom services added")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Add your own terminal commands (e.g. restart Docker, restart a local web server, or custom daemons).")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 320)
                    
                    Button("Create Custom Service") {
                        showingAddSheet = true
                    }
                    .padding(.top, 6)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(serviceManager.customServices) { service in
                            VStack(spacing: 6) {
                                ServiceCardView(service: service)
                                
                                HStack {
                                    Spacer()
                                    Button(role: .destructive) {
                                        serviceManager.deleteCustomService(id: service.id)
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: "trash")
                                                .font(.system(size: 10))
                                            Text("Delete Custom Service")
                                                .font(.system(size: 11))
                                        }
                                        .foregroundColor(.red)
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.trailing, 10)
                                }
                            }
                        }
                    }
                    .padding(18)
                }
            }
        }
    }
}
