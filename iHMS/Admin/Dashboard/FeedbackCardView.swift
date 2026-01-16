import SwiftUI

struct FeedbackCardView: View {
    let item: Feedback
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Left Side: Info
            VStack(alignment: .leading, spacing: 6) {
                Text(item.patient?.fullName ?? "Anonymous")
                    .font(.headline)
                    .foregroundColor(Theme.primaryText)
                
                if let doctorName = item.doctor?.fullName {
                    Text("Dr. \(doctorName)")
                        .font(.caption)
                        .foregroundColor(Theme.secondaryText)
                }
                
                if let comments = item.comments {
                    Text(comments)
                        .font(.subheadline)
                        .foregroundColor(Theme.secondaryText)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .padding(.top, 2)
                }
            }
            
            Spacer()
            
            // Right Side: Rating & Date
            VStack(alignment: .trailing, spacing: 6) {
                HStack(spacing: 2) {
                    ForEach(0..<5) { i in
                        Image(systemName: i < (item.rating ?? 0) ? "star.fill" : "star")
                            .font(.caption)
                            .foregroundColor(i < (item.rating ?? 0) ? .yellow : .gray)
                    }
                }
                
                Text(item.formattedDate)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Theme.surface)
        .cornerRadius(12)
    }
}
