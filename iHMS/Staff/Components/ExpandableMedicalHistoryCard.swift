import SwiftUI

struct ExpandableMedicalHistoryCard: View {
    let patient: Patient
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Button
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "doc.text.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.purple)
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Medical History")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        Text(isExpanded ? "Tap to collapse" : "View patient medical history")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding()
                .background(Color(.systemGray6)) // Matches existing card backgrounds
            }
            .buttonStyle(.plain)
            
            // Expanded Content
            if isExpanded {
                VStack(alignment: .leading, spacing: 20) {
                    
                    VStack(alignment: .leading, spacing: 16) {
                        // Section 1: History
                        FormLikeSection(title: "PAST MEDICAL SITUATIONS") {
                            if let history = patient.medicalHistory, !history.isEmpty {
                                Text(history)
                                    .foregroundStyle(.primary)
                            } else {
                                EmptyStateText()
                            }
                        }
                        
                        // Section 2: Allergies
                        FormLikeSection(title: "ALLERGIES") {
                            if let allergies = patient.allergies, !allergies.isEmpty {
                                Text(allergies.joined(separator: ", "))
                                    .foregroundStyle(.primary)
                            } else {
                                EmptyStateText()
                            }
                        }
                        
                        // Section 3: Medications
                        FormLikeSection(title: "CURRENT MEDICATIONS") {
                            if let medications = patient.currentMedications, !medications.isEmpty {
                                Text(medications.joined(separator: ", "))
                                    .foregroundStyle(.primary)
                            } else {
                                EmptyStateText()
                            }
                        }
                    }
                    .padding()
                }
                .background(Color(.systemGray6).opacity(0.5))
            }
        }
        .background(Color(.systemBackground)) // Main card background
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color(.systemGray4), lineWidth: 0.5)
        )
    }
}

private struct FormLikeSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .padding(.leading, 4)
            
            VStack(alignment: .leading) {
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(10)
        }
    }
}

private struct EmptyStateText: View {
    var body: some View {
        Text("No records found")
            .foregroundStyle(.secondary)
            .italic()
    }
}
