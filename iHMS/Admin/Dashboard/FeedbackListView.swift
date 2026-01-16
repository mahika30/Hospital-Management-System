import SwiftUI

struct FeedbackListView: View {
    let feedbacks: [Feedback]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(feedbacks) { item in
                    FeedbackCardView(item: item)
                }
            }
            .padding()
        }
        .background(Theme.background)
        .navigationTitle("All Feedbacks")
        .navigationBarTitleDisplayMode(.inline)
    }
}
