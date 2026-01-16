import SwiftUI

struct FeedbackCardView: View {
    let item: Feedback
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(item.patient?.fullName ?? "Anonymous")
                    .font(.headline)
                    .foregroundColor(Theme.primaryText)
                
                Spacer()
                
                HStack(spacing: 2) {
                    ForEach(0..<5) { i in
                        Image(systemName: i < item.rating ? "star.fill" : "star")
                            .font(.caption)
                            .foregroundColor(i < item.rating ? .yellow : .gray)
                    }
                }
            }
            
            if let comments = item.comments {
                Text(comments)
                    .font(.subheadline)
                    .foregroundColor(Theme.secondaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding()
        .background(Theme.surface)
        .cornerRadius(12)
    }
}
