import SwiftUI

struct AdminHomeTab: View {

    @StateObject private var dashboardVM = AdminDashboardViewModel()
    private let gridColumns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                LazyVGrid(columns: gridColumns, spacing: 16) {
                    SummaryCard(
                        title: "Patients",
                        count: dashboardVM.patientsCount,
                        iconName: "person.2.fill",
                        accent: .blue,
                        deltaText: "+12%"
                    )

                    SummaryCard(
                        title: "Appointments",
                        count: dashboardVM.appointmentsCount,
                        iconName: "calendar.badge.clock",
                        accent: .green,
                        deltaText: "+8%"
                    )
                }
                .padding(.horizontal)

                // Analytics
                AnalyticsView(viewModel: dashboardVM)
                    .frame(height: 360)

                // Feedback
                feedbackSection
            }
            .padding(.vertical)
        }
        .background(Theme.background)
        .refreshable {
            await dashboardVM.fetchDashboardStats()
        }
        .task {
            // Fetch real data when the tab appears
            await dashboardVM.fetchDashboardStats()
        }
    }

    private var feedbackSection: some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack {
                Text("Patient Feedback")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Theme.primaryText)

                Spacer()
            }

            VStack(spacing: 12) {
                ForEach(Array(dashboardVM.recentFeedbacks.prefix(3))) { item in
                    FeedbackCardView(item: item)
                }
            }
            .comingSoon() // Apply Coming Soon overlay only to the content
        }
        .padding(.horizontal)
    }
}

// MARK: - Coming Soon Overlay
struct ComingSoonModifier: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            content
                .blur(radius: 10) // Direct blur on the content
                .allowsHitTesting(false) // Disable interaction with the blurred content
            
            Text("COMING SOON")
                .font(.title3)
                .fontWeight(.bold)
                .tracking(4) // Wide letter spacing
                .foregroundColor(Theme.primaryText)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
        }
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
    }
}

extension View {
    func comingSoon() -> some View {
        modifier(ComingSoonModifier())
    }
}
