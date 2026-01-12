import SwiftUI

enum AdminTab {
    case home, staff, reports
}

struct AdminDashboardView: View {

    @EnvironmentObject var authVM: AuthViewModel
    @State private var showProfileSheet = false
    @State private var showAddStaffSheet = false
    @State private var selectedTab: AdminTab = .home
    @State private var currentUserName: String = "Admin"

    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {

                AdminHomeTab()
                    .tag(AdminTab.home)
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }

                AdminStaffTab()
                    .tag(AdminTab.staff)
                    .tabItem {
                        Label("Staff", systemImage: "person.3.fill")
                    }

                AdminReportsTab()
                    .tag(AdminTab.reports)
                    .tabItem {
                        Label("Reports", systemImage: "chart.bar.fill")
                    }
            }
            .navigationTitle(titleForTab)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {

                if selectedTab == .staff {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showAddStaffSheet = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showProfileSheet = true
                    } label: {
                        Image(systemName: "person.crop.circle")
                    }
                }
            }
            .task {
                currentUserName = await authVM.currentUserName()
            }
            .sheet(isPresented: $showProfileSheet) {
                AdminSettingsTab()
                    .environmentObject(authVM)
            }
            .onChange(of: showProfileSheet) { newValue in
                if !newValue {
                    Task {
                        currentUserName = await authVM.currentUserName()
                    }
                }
            }
            .sheet(isPresented: $showAddStaffSheet) {
                AddStaffView()
            }
        }
    }

    private var titleForTab: String {
        switch selectedTab {
        case .home:
            return "\(currentUserName)"
        case .staff:
            return "Staff"
        case .reports:
            return "Reports"
        }
    }
}
