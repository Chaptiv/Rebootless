import SwiftUI

public struct ServiceListView: View {
    @EnvironmentObject var serviceManager: ServiceManager
    
    public var body: some View {
        VStack(spacing: 0) {
            // Filter Bar
            VStack(spacing: 10) {
                // Search Field
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search service, issue, or keyword (e.g. sound, frozen, wifi, airpods)...", text: $serviceManager.searchText)
                        .textFieldStyle(.plain)
                    
                    if !serviceManager.searchText.isEmpty {
                        Button {
                            serviceManager.searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
                
                // Category Pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(ServiceCategory.allCases) { category in
                            CategoryPill(
                                category: category,
                                isSelected: serviceManager.selectedCategory == category,
                                count: countForCategory(category)
                            ) {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                    serviceManager.selectedCategory = category
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 12)
            .background(Color(nsColor: .windowBackgroundColor))
            
            Divider()
            
            // Services Content
            if serviceManager.filteredServices.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary)
                    Text("No services found")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Try searching with different terms like 'finder', 'sound', 'wifi', or select another category.")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 340)
                    
                    if !serviceManager.searchText.isEmpty {
                        Button("Clear Search") {
                            serviceManager.searchText = ""
                        }
                        .padding(.top, 6)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(serviceManager.filteredServices) { service in
                            ServiceCardView(service: service)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 16)
                }
            }
        }
    }
    
    private func countForCategory(_ category: ServiceCategory) -> Int {
        if category == .all {
            return serviceManager.services.count
        } else if category == .custom {
            return serviceManager.services.filter { !$0.isBuiltIn }.count
        } else {
            return serviceManager.services.filter { $0.category == category }.count
        }
    }
}

private struct CategoryPill: View {
    let category: ServiceCategory
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: category.iconName)
                    .font(.system(size: 11))
                Text(category.rawValue)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                
                Text("\(count)")
                    .font(.system(size: 10, weight: .semibold))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(isSelected ? Color.white.opacity(0.25) : Color.primary.opacity(0.08))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(isSelected ? Color.accentColor : Color.primary.opacity(0.05))
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}
