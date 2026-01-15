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
    @State private var currentMonth = Date().addingTimeInterval(7 * 24 * 60 * 60)
    
    var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }
    
    var daysInMonth: [Date] {
        let calendar = Calendar.current
        let interval = calendar.dateInterval(of: .month, for: currentMonth)!
        let days = calendar.dateComponents([.day], from: interval.start, to: interval.end).day!
        return (0..<days).compactMap {
            calendar.date(byAdding: .day, value: $0, to: interval.start)
        }
    }
    
    func previousMonth() {
        let calendar = Calendar.current
        if let newDate = calendar.date(byAdding: .month, value: -1, to: currentMonth) {
            currentMonth = newDate
        }
    }
    
    func nextMonth() {
        let calendar = Calendar.current
        if let newDate = calendar.date(byAdding: .month, value: 1, to: currentMonth) {
            currentMonth = newDate
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Date Picker Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Follow-up Date")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            // Month/Year Header with Navigation
                            HStack {
                                Button(action: { previousMonth() }) {
                                    Image(systemName: "chevron.left")
                                        .font(.title3)
                                        .foregroundColor(.blue)
                                }
                                
                                Spacer()
                                
                                Text(monthYearString)
                                    .font(.headline)
                                
                                Spacer()
                                
                                Button(action: { nextMonth() }) {
                                    Image(systemName: "chevron.right")
                                        .font(.title3)
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.horizontal)
                            
                            // Horizontal scrolling date picker
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(daysInMonth, id: \.self) { date in
                                        FollowUpDateCell(
                                            date: date,
                                            isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                                            isToday: Calendar.current.isDateInToday(date),
                                            isPast: date < Date()
                                        )
                                        .onTapGesture {
                                            if date >= Date() {
                                                selectedDate = date
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                            
                            // Selected day display
                            Text(formatSelectedDate(selectedDate))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
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
    
    private func formatSelectedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d, yyyy"
        return formatter.string(from: date)
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

struct FollowUpDateCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let isPast: Bool
    
    private var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Text(dayName)
                .font(.caption2)
                .foregroundStyle(isSelected ? .white : (isPast ? .secondary.opacity(0.5) : .secondary))
            
            Text(dayNumber)
                .font(.system(size: 16, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? .white : (isPast ? .primary.opacity(0.3) : .primary))
        }
        .frame(width: 50, height: 60)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.blue : (isToday ? Color.blue.opacity(0.1) : Color.clear))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isToday && !isSelected ? Color.blue : Color.clear, lineWidth: 1)
        )
        .opacity(isPast ? 0.4 : 1.0)
    }
}
