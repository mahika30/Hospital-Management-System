//
//  MedicalReportPreviewScene.swift
//  iHMS
//
//  Created for Medical Reports Feature
//  Using existing MedicalReportService
//

import SwiftUI
import PDFKit

struct MedicalReportPreviewScene: View {
    
    let report: MedicalReport
    
    @State private var signedURL: URL?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground).ignoresSafeArea()
            
            if isLoading {
                ProgressView("Fetching document...")
            } else if let error = errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundStyle(.red)
                    Text("Could not load preview")
                        .font(.headline)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else if let url = signedURL {
                if isPDF {
                    PDFKitView(url: url)
                } else {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        case .failure:
                            ContentUnavailableView("Failed to load image", systemImage: "photo.badge.exclamationmark")
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
            }
        }
        .navigationTitle(report.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .task {
            await loadSignedURL()
        }
    }
    
    @Environment(\.dismiss) private var dismiss
    
    private var isPDF: Bool {
        report.fileType.lowercased().contains("pdf")
    }
    
    private func loadSignedURL() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let url = try await MedicalReportService.shared.getSignedURL(for: report)
            await MainActor.run {
                self.signedURL = url
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

// MARK: - PDFKit Wrapper
struct PDFKitView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        if uiView.document?.documentURL != url {
            uiView.document = PDFDocument(url: url)
        }
    }
}
