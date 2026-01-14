//
//  PrescriptionsListView.swift
//  iHMS
//
//  Created on 13/01/2026.
//

import SwiftUI

struct PrescriptionsListView: View {
    @StateObject private var viewModel: PrescriptionsViewModel
    
    init(patientId: UUID) {
        _viewModel = StateObject(wrappedValue: PrescriptionsViewModel(patientId: patientId))
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                } else if viewModel.prescriptions.isEmpty {
                    emptyState
                } else {
                    prescriptionsList
                }
            }
            .navigationTitle("My Prescriptions")
            .task {
                await viewModel.loadPrescriptions()
            }
            .refreshable {
                await viewModel.loadPrescriptions()
            }
        }
    }
    
    private var prescriptionsList: some View {
        List(viewModel.prescriptions) { prescription in
            NavigationLink {
                PrescriptionDetailView(prescription: prescription)
            } label: {
                PrescriptionRow(prescription: prescription)
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            Text("No Prescriptions")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Your prescriptions will appear here after doctor consultations")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
}

struct PrescriptionRow: View {
    let prescription: Prescription
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(.blue)
                
                Text("Prescription")
                    .font(.headline)
                
                Spacer()
                
                Text(formatDate(prescription.prescriptionDate))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let diagnosis = prescription.diagnosis {
                Text(diagnosis)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            if let medicinesCount = prescription.medicines?.count {
                Label("\(medicinesCount) medicines", systemImage: "pills")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            if let followUpDate = prescription.followUpDate {
                Label("Follow-up: \(followUpDate)", systemImage: "calendar.badge.clock")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withFullDate]
        
        guard let date = isoFormatter.date(from: dateString) else {
            return dateString
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
