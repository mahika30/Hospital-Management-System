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
                        count: 1240,
                        iconName: "person.2.fill",
                        accent: .blue,
                        deltaText: "+12%"
                    )

                    SummaryCard(
                        title: "Appointments",
                        count: 320,
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
    }

    private var feedbackSection: some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack {
                Text("Patient Feedback")
                    .font(.headline)
                    .foregroundColor(Theme.primaryText)

                Spacer()

                NavigationLink {
                    FeedbackListView(feedbacks: dashboardVM.recentFeedbacks)
                } label: {
                    Text("View All")
                        .font(.subheadline)
                        .foregroundColor(Theme.accent)
                }
            }

            ForEach(Array(dashboardVM.recentFeedbacks.prefix(3))) { item in
                FeedbackCardView(item: item)
            }
        }
        .padding(.horizontal)
    }
}
