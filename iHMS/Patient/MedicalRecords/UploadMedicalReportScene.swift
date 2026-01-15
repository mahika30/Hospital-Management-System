//
//  UploadMedicalReportScene.swift
//  iHMS
//
//  Created for Medical Reports Feature
//  Using existing MedicalReportService
//

import SwiftUI
import UniformTypeIdentifiers

struct UploadMedicalReportScene: View {
    
    // MARK: - Inputs
    let userId: UUID
    var onUploadSuccess: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    // Form Selection
    @State private var selectedCategory: String? = nil
    @State private var title: String = ""
    @State private var description: String = ""
    
    // File
    @State private var fileName: String?
    @State private var fileData: Data?
    @State private var fileType: String?
    @State private var showFileImporter = false
    
    // Status
    @State private var isUploading = false
    @State private var errorMessage: String?
    @State private var showAlert = false
    
    private let categories = [
        "Lab Reports",
        "Radiology / Imaging",
        "Discharge Summaries",
        "Doctor Notes",
        "Surgery / Procedure Reports",
        "Insurance / Billing Documents",
        "Other Medical Documents"
    ]
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hue: 0, saturation: 0, brightness: 0.08) // Dark background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // 1. Categories
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Select Category")
                                .font(.headline)
                                .foregroundStyle(.white)
                            
                            FlowLayout(spacing: 12) {
                                ForEach(categories, id: \.self) { category in
                                    CategoryChip(
                                        title: category,
                                        isSelected: selectedCategory == category
                                    ) {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedCategory = category
                                        }
                                    }
                                }
                            }
                        }
                        
                        // 2. Details
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Report Details")
                                .font(.headline)
                                .foregroundStyle(.white)
                            
                            CustomDarkTextField(placeholder: "Report Title (e.g. Blood Test)", text: $title)
                            
                            CustomDarkTextField(placeholder: "Description (Optional)", text: $description, isMultiline: true)
                        }
                        
                        // 3. Document
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Document")
                                .font(.headline)
                                .foregroundStyle(.white)
                            
                            Button {
                                showFileImporter = true
                            } label: {
                                HStack {
                                    if let name = fileName {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                        Text(name)
                                            .lineLimit(1)
                                            .foregroundStyle(.white)
                                    } else {
                                        Image(systemName: "paperclip")
                                        Text("Select File (PDF or Image)")
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(white: 0.15))
                                .cornerRadius(12)
                                .foregroundStyle(fileName == nil ? .blue : .white)
                            }
                        }
                        
                        // Error message
                        if let error = errorMessage {
                            Text(error)
                                .foregroundStyle(.red)
                                .font(.caption)
                        }
                        
                        Spacer(minLength: 20)
                    }
                    .padding(20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                 // Custom Toolbar to match Dark Theme
                ToolbarItem(placement: .principal) {
                    Text("Upload Report")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.white)
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Task { await uploadReport() }
                    } label: {
                        if isUploading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Upload")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(isFormInvalid || isUploading)
                    .foregroundStyle(isFormInvalid ? .gray : .white)
                }
            }
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [.pdf, .image],
                allowsMultipleSelection: false
            ) { result in
                handleFileSelection(result)
            }
        }
    }
    
    // MARK: - Logic
    
    var isFormInvalid: Bool {
        selectedCategory == nil || title.trimmingCharacters(in: .whitespaces).isEmpty || fileData == nil
    }
    
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        do {
            guard let selectedFile = try result.get().first else { return }
            
            if selectedFile.startAccessingSecurityScopedResource() {
                defer { selectedFile.stopAccessingSecurityScopedResource() }
                
                let data = try Data(contentsOf: selectedFile)
                // Basic Validation
                if data.count > 10 * 1024 * 1024 { // 10 MB limit check UI side
                     self.errorMessage = "File too large (Max 10MB)"
                     return
                }
                
                self.fileData = data
                self.fileName = selectedFile.lastPathComponent
                self.fileType = selectedFile.pathExtension
                self.errorMessage = nil
            }
        } catch {
            self.errorMessage = "Could not read file: \(error.localizedDescription)"
        }
    }
    
    private func uploadReport() async {
        guard let category = selectedCategory,
              let data = fileData,
              let type = fileType else { return }
        
        isUploading = true
        errorMessage = nil
        
        let finalDescription = "[\(category)] \(description)"
        
        do {
            try await MedicalReportService.shared.uploadReport(
                userId: userId,
                title: title,
                description: finalDescription,
                fileData: data,
                fileType: type
            )
            await MainActor.run {
                isUploading = false
                onUploadSuccess()
                dismiss()
            }
        } catch {
            await MainActor.run {
                isUploading = false
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - UI Components

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                .foregroundStyle(isSelected ? .white : .gray)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue.opacity(0.3) : Color.clear)
                .cornerRadius(8)
                .overlay(
                     // Minimal or no border as per screenshot
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

struct CustomDarkTextField: View {
    let placeholder: String
    @Binding var text: String
    var isMultiline: Bool = false
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .foregroundStyle(.gray.opacity(0.7))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
            }
            
            if isMultiline {
                TextField("", text: $text, axis: .vertical)
                    .lineLimit(3...6)
                    .padding(12)
                    .foregroundStyle(.white)
            } else {
                TextField("", text: $text)
                    .padding(12)
                    .foregroundStyle(.white)
            }
        }
        .background(Color(white: 0.12)) // Dark input background
        .cornerRadius(8)
    }
}

// Simple Flow Layout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrangeSubviews(proposal: proposal, subviews: subviews)
        return CGSize(width: proposal.width ?? 0, height: rows.last?.maxY ?? 0)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = arrangeSubviews(proposal: proposal, subviews: subviews)
        for row in rows {
            for item in row.items {
                item.view.place(at: CGPoint(x: bounds.minX + item.x, y: bounds.minY + row.y), proposal: .unspecified)
            }
        }
    }
    
    private struct Row {
        var y: CGFloat
        var maxY: CGFloat
        var items: [Item]
    }
    
    private struct Item {
        var x: CGFloat
        var view: LayoutSubview
    }
    
    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var currentY: CGFloat = 0
        var currentX: CGFloat = 0
        var currentRowItems: [Item] = []
        var currentRowMaxH: CGFloat = 0
        
        let maxWidth = proposal.width ?? .infinity
        
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            
            if currentX + size.width > maxWidth && !currentRowItems.isEmpty {
                rows.append(Row(y: currentY, maxY: currentY + currentRowMaxH, items: currentRowItems))
                currentY += currentRowMaxH + spacing
                currentX = 0
                currentRowItems = []
                currentRowMaxH = 0
            }
            
            currentRowItems.append(Item(x: currentX, view: view))
            currentX += size.width + spacing
            currentRowMaxH = max(currentRowMaxH, size.height)
        }
        
        if !currentRowItems.isEmpty {
            rows.append(Row(y: currentY, maxY: currentY + currentRowMaxH, items: currentRowItems))
        }
        
        return rows
    }
}
