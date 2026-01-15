//
//  MedicalReportsScene.swift
//  iHMS
//
//  Created for Medical Reports Feature
//  Using existing MedicalReportService
//

import SwiftUI

struct MedicalReportsScene: View {
    
    // MARK: - Input
    let userId: UUID
    
    // MARK: - State
    @State private var reports: [MedicalReport] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var showUploadSheet: Bool = false
    
    // Navigation State
    @State private var navigationPath = NavigationPath()
    
    // Delete handling
    @State private var deleteError: String? = nil
    @State private var showingDeleteError = false
    
    // Columns for Grid
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    // MARK: - Body
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if isLoading && reports.isEmpty {
                    ProgressView().tint(.white)
                } else if let error = errorMessage, reports.isEmpty {
                    ContentUnavailableView {
                        Label("Error", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(error)
                    } actions: {
                        Button("Retry") { Task { await loadReports() } }
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            
                            // Grid of Categories
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(MedicalReportCategory.allCases, id: \.self) { category in
                                    let categoryReports = reportsForCategory(category)
                                    
                                    NavigationLink(value: category) {
                                        GreyCategoryCard(
                                            category: category,
                                            count: categoryReports.count
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 40)
                        }
                    }
                    .refreshable {
                        await loadReports(isRefresh: true)
                    }
                }
            }
            .navigationTitle("All Records")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                 // Add Button Top Right
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showUploadSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .font(.system(size: 28))
                            .foregroundStyle(Color.blue)
                    }
                }
            }
            .navigationDestination(for: String.self) { categoryName in
                CategoryDetailView(
                    categoryName: categoryName,
                    reports: reportsForCategory(categoryName),
                    onDelete: { report in
                        Task { await deleteReport(report) }
                    }
                )
            }
            .sheet(isPresented: $showUploadSheet) {
                UploadMedicalReportScene(userId: userId) {
                    Task { await loadReports(isRefresh: true) }
                }
            }
            .alert("Delete Failed", isPresented: $showingDeleteError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(deleteError ?? "Unknown error")
            }
            .task {
                await loadReports()
            }
        }
    }
    
    // MARK: - Logic
    
    private struct MedicalReportCategory {
        static let allCases = [
            "Lab Reports",
            "Radiology / Imaging",
            "Discharge Summaries",
            "Doctor Notes",
            "Surgery / Procedure Reports",
            "Insurance / Billing Documents",
            "Other Medical Documents"
        ]
    }
    
    private func reportsForCategory(_ category: String) -> [MedicalReport] {
        return reports.filter { report in
            guard let desc = report.description else {
                return category == "Other Medical Documents"
            }
            if desc.contains("[\(category)]") { return true }
            if category == "Other Medical Documents" {
                let isKnown = MedicalReportCategory.allCases.contains { desc.contains("[\($0)]") }
                return !isKnown
            }
            return false
        }
    }
    
    private func loadReports(isRefresh: Bool = false) async {
        if !isRefresh { isLoading = true }
        errorMessage = nil
        do {
            let fetched = try await MedicalReportService.shared.fetchReports(for: userId)
            await MainActor.run {
                withAnimation {
                    self.reports = fetched
                    self.isLoading = false
                }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    private func deleteReport(_ report: MedicalReport) async {
        let originalReports = reports
        if let index = reports.firstIndex(where: { $0.id == report.id }) {
            withAnimation {
                 reports.remove(at: index)
            }
        }
        
        do {
            try await MedicalReportService.shared.deleteReport(report)
        } catch {
            await MainActor.run {
                self.reports = originalReports
                self.deleteError = "Could not delete: \(error.localizedDescription)"
                self.showingDeleteError = true
            }
        }
    }
}

// MARK: - Grey Category Card (Updated)
struct GreyCategoryCard: View {
    let category: String
    let count: Int
    
    // All Grey as requested
    private let cardColor = Color(hue: 0, saturation: 0, brightness: 0.15) // Dark Grey
    
    private var icon: String {
        switch category {
        case "Lab Reports": return "cross.case.fill"
        case "Radiology / Imaging": return "rays"
        case "Discharge Summaries": return "arrow.right.doc.on.clipboard"
        case "Doctor Notes": return "stethoscope"
        case "Surgery / Procedure Reports": return "bandage.fill"
        case "Insurance / Billing Documents": return "banknote.fill"
        case "Other Medical Documents": return "folder.fill"
        default: return "doc.fill"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.blue) // Blue Icon
                }
                
                Spacer()
                
                Text("\(count)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.blue) // Blue Count
            }
            
            Spacer()
            
            // Fixed Title Cropping: minimumScaleFactor + layoutPriority
            Text(category)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .minimumScaleFactor(0.8) // Allows text to shrink slightly to fit
                .fixedSize(horizontal: false, vertical: true) // Allows wrapping
        }
        .padding(14)
        .frame(height: 100)
        .background(cardColor)
        .cornerRadius(16)
    }
}

// MARK: - Category Detail View
struct CategoryDetailView: View {
    let categoryName: String
    let reports: [MedicalReport]
    let onDelete: (MedicalReport) -> Void
    
    @State private var selectedReport: MedicalReport?
    @State private var searchText = ""
    
    var filteredReports: [MedicalReport] {
        if searchText.isEmpty { return reports }
        return reports.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if reports.isEmpty {
                ContentUnavailableView(
                    "No Reports",
                    systemImage: "folder.open",
                    description: Text("No records found in \(categoryName)")
                )
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 16)], spacing: 16) {
                            ForEach(filteredReports) { report in
                                GlassDetailCard(report: report)
                                    .onTapGesture { selectedReport = report }
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            onDelete(report)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top, 10)
                }
            }
        }
        .navigationTitle("") 
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(categoryName)
                    .font(.headline)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .foregroundStyle(.white)
            }
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer, prompt: "Search")
        .sheet(item: $selectedReport) { report in
            NavigationStack {
                MedicalReportPreviewScene(report: report)
            }
        }
    }
}

// Detail Card (Dark Grey Theme)
struct GlassDetailCard: View {
    let report: MedicalReport
    
    private var isPDF: Bool {
        report.fileType.lowercased().contains("pdf")
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: report.createdAt)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: isPDF ? "doc.text.fill" : "photo.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(isPDF ? Color.red : Color.blue)
                Spacer()
                Text(isPDF ? "PDF" : "IMG")
                    .font(.caption2.bold())
                    .foregroundStyle(.gray)
                    .padding(4)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(4)
            }
            Spacer()
            Text(report.title)
                .font(.headline)
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.9)
            Text(formattedDate)
                .font(.caption)
                .foregroundStyle(.gray)
        }
        .padding()
        .frame(height: 140)
        .background(Color(white: 0.12)) // Dark Grey Card
        .cornerRadius(16)
    }
}
