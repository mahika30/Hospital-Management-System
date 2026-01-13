//
//  RecommendFollowUpSheet.swift
//  iHMS
//
//  Created on 13/01/2026.
//

import SwiftUI

struct RecommendFollowUpSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var followUpDate: Date?
    @Binding var followUpNotes: String
    
    @State private var selectedDate = Date().addingTimeInterval(7 * 24 * 60 * 60) // Default: 1 week from now
    @State private var notes = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Date Picker Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Follow-up Date")
                            .font(.headline)
                        
                        DatePicker(
                            "Select Date",
                            selection: $selectedDate,
                            in: Date()...,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.graphical)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    // Quick Selections
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Selections")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            QuickSelectButton(title: "1 Week", icon: "calendar.badge.plus") {
                                selectedDate = Date().addingTimeInterval(7 * 24 * 60 * 60)
                            }
                            QuickSelectButton(title: "2 Weeks", icon: "calendar") {
                                selectedDate = Date().addingTimeInterval(14 * 24 * 60 * 60)
                            }
                            QuickSelectButton(title: "1 Month", icon: "calendar.badge.clock") {
                                selectedDate = Date().addingTimeInterval(30 * 24 * 60 * 60)
                            }
                            QuickSelectButton(title: "3 Months", icon: "calendar.circle") {
                                selectedDate = Date().addingTimeInterval(90 * 24 * 60 * 60)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Follow-up Notes
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Follow-up Notes")
                            .font(.headline)
                        
                        TextEditor(text: $notes)
                            .frame(height: 120)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal)
                    
                    // Add Button
                    Button {
                        followUpDate = selectedDate
                        followUpNotes = notes
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "calendar.badge.checkmark")
                                .font(.headline)
                            Text("Add Follow-up Appointment")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color.blue, Color.blue.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
                .padding(.top)
            }
            .navigationTitle("Recommend Follow-up")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct QuickSelectButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Color.blue.opacity(0.1))
            .foregroundColor(.blue)
            .cornerRadius(12)
        }
    }
}
