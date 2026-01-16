//
//  MedicalReportListView.swift
//  iHMS
//
//  Created for Medical Reports Feature
//  Using existing MedicalReportService and Models
//

import SwiftUI

struct MedicalReportListView: View {
    
    // MARK: - Input
    let userId: UUID
    
    // MARK: - State
    @State private var reports: [MedicalReport] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                if isLoading {
                    ProgressView("Loading reports...")
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundStyle(.gray)
                        Text(error)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Button("Retry") {
                            Task { await loadReports() }
                        }
                    }
                } else if reports.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "folder.badge.questionmark")
                            .font(.system(size: 48))
                            .foregroundStyle(.blue.opacity(0.6))
                        Text("No reports found")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text("Any uploaded medical records will appear here.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    // Folder-Style List
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(reports) { report in
                                ReportCard(report: report)
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        await loadReports()
                    }
                }
            }
            .navigationTitle("Medical Reports")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // Action Placeholder
                        print("Add Report tapped - Placeholder for upload sheet")
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add Report")
                }
            }
            .task {
                await loadReports()
            }
        }
    }
    
    // MARK: - Data Loading
    private func loadReports() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Fetch reports using existing shared service
            let fetched = try await MedicalReportService.shared.fetchReports(for: userId)
            
            // UI Update on Main Actor
            await MainActor.run {
                self.reports = fetched
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
}

// MARK: - Subviews

struct ReportCard: View {
    let report: MedicalReport
    
    // Computed icon based on file type
    private var iconName: String {
        let type = report.fileType.lowercased()
        if type.contains("pdf") {
            return "doc.text.fill"
        } else if type.contains("jpg") || type.contains("png") || type.contains("jpeg") {
            return "photo.fill"
        }
        return "doc.fill"
    }
    
    private var iconColor: Color {
        let type = report.fileType.lowercased()
        if type.contains("pdf") {
            return .red
        }
        return .blue
    }
    
    // Date Formatter
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: report.createdAt)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            
            // 📄 Preview / Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 48, height: 48)
                
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundStyle(iconColor)
            }
            
            // 📝 Details
            VStack(alignment: .leading, spacing: 4) {
                Text(report.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                Text(formattedDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
        // Subtle Shadow
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(report.title), uploaded \(formattedDate)")
        .accessibilityHint("Double tap to view report")
    }
}

// MARK: - Preview
// Requires dummy data which we strictly avoid hardcoding in main logic, 
// using generic stub for Preview provider if needed, or omitted complying with strict rules.
#Preview {
    MedicalReportListView(userId: UUID())
}
