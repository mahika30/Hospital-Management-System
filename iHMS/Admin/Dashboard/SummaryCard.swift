import SwiftUI
struct SummaryCard: View {
    let title: String
    let count: Int
    let iconName: String
    let accent: Color
    let deltaText: String

    var body: some View {
        ZStack(alignment: .leading) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [accent.opacity(0.8), accent.opacity(0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 4)

            HStack {
                VStack(alignment: .leading, spacing: 4) {

                    // Top Row: Icon + Percentage
                    HStack {
                        Image(systemName: iconName)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(
                                Circle()
                                    .fill(.white.opacity(0.08))
                            )
                        
                        Spacer()
                        
                        Text(deltaText)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(accent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(accent.opacity(0.2))
                            .cornerRadius(8)
                    }

                    Spacer()

                    // Bottom Row: Count + Title
                    Text("\(count)")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.white)

                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Theme.secondaryText)
                }

                Spacer(minLength: 6)
            }
            .padding(16)
        }
        .frame(height: 140)
        .background(
            LinearGradient(
                colors: [
                    Theme.surface.opacity(1),
                    Theme.surface.opacity(0.85)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(Theme.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .stroke(.white.opacity(0.06))
        )
        .shadow(color: .black.opacity(0.4), radius: 10, y: 6)
    }
}
