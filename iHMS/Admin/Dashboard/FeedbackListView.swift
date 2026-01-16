import SwiftUI

struct FeedbackListView: View {
    let feedbacks: [Feedback]
    
    @State private var selectedFilter: FeedbackFilter = .thisWeek
    
    enum FeedbackFilter: String, CaseIterable {
        case today = "Today"
        case thisWeek = "This Week"
        case older = "Older"
    }
    
    var filteredFeedbacks: [Feedback] {
        let calendar = Calendar.current
        let now = Date()
        
        return feedbacks.filter { feedback in
            let date = feedback.createdDate
            
            switch selectedFilter {
            case .today:
                return calendar.isDateInToday(date)
            case .thisWeek:
                // "This Week" includes Today in standard calendar week logic
                return calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear)
            case .older:
                // Older than this week
                return !calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear)
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Filter Picker
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(FeedbackFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // List
                LazyVStack(spacing: 16) {
                    if filteredFeedbacks.isEmpty {
                        Text("No feedback found")
                            .foregroundColor(.gray)
                            .padding(.top, 40)
                    } else {
                        ForEach(filteredFeedbacks) { item in
                            FeedbackCardView(item: item)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Theme.background)
        .navigationTitle("All Feedbacks")
        .navigationBarTitleDisplayMode(.inline)
    }
}
