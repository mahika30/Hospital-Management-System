//
//  TimeSlotCard.swift
//  iHMS
//
//  Created on 08/01/2026.
//

import SwiftUI

struct TimeSlotCard: View {
    let slot: TimeSlot
    let isToggled: Bool
    let onToggle: () -> Void
    let onCapacityChange: ((Int) -> Void)?
    let onEmergencyCancel: (() -> Void)?
    let onMarkRunningLate: (() -> Void)?
    let onClearRunningLate: (() -> Void)?
    
    @State private var isPressed = false
    @State private var showingCapacityEditor = false
    @State private var offset: CGFloat = 0
    @State private var showingSwipeActions = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: slot.isRunningLate ? "clock.badge.exclamationmark.fill" : "clock.fill")
                        .font(.title3)
                        .foregroundStyle(statusColor.gradient)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(timeText)
                            .font(.system(.headline, design: .rounded))
                            .fontWeight(.semibold)
                        
                        Text(slot.status.rawValue)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                if slot.isAvailable {
                    Button(action: {
                        showingCapacityEditor = true
                        hapticFeedback()
                    }) {
                        CapacityBadge(
                            current: slot.currentBookings,
                            maximum: slot.maxCapacity,
                            percentage: slot.fillPercentage
                        )
                    }
                    .buttonStyle(.plain)
                }
                
                Toggle("", isOn: Binding(
                    get: { isToggled },
                    set: { _ in
                        hapticFeedback()
                        onToggle()
                    }
                ))
                .labelsHidden()
                .tint(statusColor)
            }
            .padding(16)
            
            // Running Late Banner
            if slot.isRunningLate && slot.delayMinutes > 0 {
                HStack(spacing: 10) {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.badge.exclamationmark.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                        
                        Text("Running \(slot.delayMinutes) min late")
                            .font(.system(.caption, design: .rounded))
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                    }
                    
                    Spacer()
                    
                    if let onClearRunningLate = onClearRunningLate {
                        Button(action: {
                            onClearRunningLate()
                            hapticFeedback()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                Text("Clear")
                                    .font(.system(.caption2, design: .rounded))
                                    .fontWeight(.bold)
                            }
                            .foregroundStyle(.black)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.yellow, Color.yellow.opacity(0.9)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .shadow(color: .yellow.opacity(0.3), radius: 4, x: 0, y: 2)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [
                            Color.yellow.opacity(0.2),
                            Color.yellow.opacity(0.15)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .shadow(color: statusColor.opacity(isToggled ? 0.15 : 0.05), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(slot.isRunningLate ? Color.yellow.opacity(0.5) : statusColor.opacity(isToggled ? 0.3 : 0), lineWidth: 2)
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isToggled)
        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: slot.isRunningLate)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if slot.isAvailable && slot.currentBookings > 0 {
                if !slot.isRunningLate {
                    Button(action: {
                        onMarkRunningLate?()
                        hapticFeedback()
                    }) {
                        Label("Running Late", systemImage: "clock.badge.exclamationmark")
                    }
                    .tint(.yellow)
                }
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            if slot.isAvailable && slot.currentBookings > 0 {
                if slot.isRunningLate {
                    Button(action: {
                        onClearRunningLate?()
                        hapticFeedback()
                    }) {
                        Label("Clear", systemImage: "checkmark.circle")
                    }
                    .tint(.green)
                }
                
                Button(role: .destructive, action: {
                    onEmergencyCancel?()
                    hapticFeedback()
                }) {
                    Label("Emergency", systemImage: "exclamationmark.triangle")
                }
            }
        }
        .contextMenu {
            if slot.isAvailable && slot.currentBookings > 0 {
                Button(role: .destructive, action: {
                    onEmergencyCancel?()
                }) {
                    Label("Emergency Cancel", systemImage: "exclamationmark.triangle.fill")
                }
                
                Divider()
                
                if slot.isRunningLate {
                    Button(action: {
                        onClearRunningLate?()
                    }) {
                        Label("Clear Running Late", systemImage: "checkmark.circle.fill")
                    }
                } else {
                    Button(action: {
                        onMarkRunningLate?()
                    }) {
                        Label("Mark Running Late", systemImage: "clock.badge.exclamationmark")
                    }
                }
            }
        }
        .sheet(isPresented: $showingCapacityEditor) {
            SlotCapacityEditor(
                slot: slot,
                onSave: { newCapacity in
                    onCapacityChange?(newCapacity)
                }
            )
            .presentationDetents([.height(280)])
            .presentationDragIndicator(.visible)
        }
    }
    
    private var timeText: String {
        // slot.startTime is already a String in "HH:mm:ss" format
        let components = slot.startTime.split(separator: ":").map(String.init)
        guard components.count >= 2,
              let hour = Int(components[0]),
              let minute = Int(components[1]) else {
            return slot.startTime
        }
        
        let isPM = hour >= 12
        let displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour)
        let period = isPM ? "PM" : "AM"
        let minuteStr = String(format: "%02d", minute)
        
        return "\(displayHour):\(minuteStr) \(period)"
    }
    
    private var statusColor: Color {
        if slot.isRunningLate {
            return .yellow
        }
        
        switch slot.status {
        case .available:
            return .green
        case .filling:
            return .orange
        case .full:
            return .red
        case .disabled:
            return .gray
        case .runningLate:
            return .yellow
        }
    }
    
    private func hapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}

struct CapacityBadge: View {
    let current: Int
    let maximum: Int
    let percentage: Double
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(lineWidth: 4)
                .foregroundStyle(Color(uiColor: .systemGray5))
                .frame(width: 50, height: 50)
            
            Circle()
                .trim(from: 0, to: percentage)
                .stroke(progressColor.gradient, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .frame(width: 50, height: 50)
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: percentage)
            
            VStack(spacing: 0) {
                Text("\(current)")
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundStyle(progressColor)
                
                Text("/ \(maximum)")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 50, height: 50)
    }
    
    private var progressColor: Color {
        if percentage >= 1.0 {
            return .red
        } else if percentage >= 0.7 {
            return .orange
        } else {
            return .green
        }
    }
}

struct SlotCapacityEditor: View {
    let slot: TimeSlot
    let onSave: (Int) -> Void
    
    @State private var selectedCapacity: Int
    @Environment(\.dismiss) private var dismiss
    
    init(slot: TimeSlot, onSave: @escaping (Int) -> Void) {
        self.slot = slot
        self.onSave = onSave
        _selectedCapacity = State(initialValue: slot.maxCapacity)
    }
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(Color.accentColor.gradient)
                
                Text("Adjust Capacity")
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.bold)
                
                Text(timeText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 20)
            
            VStack(spacing: 16) {
                HStack {
                    Button(action: {
                        if selectedCapacity > 1 {
                            selectedCapacity -= 1
                            hapticFeedback()
                        }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(selectedCapacity > 1 ? Color.accentColor : Color.gray.opacity(0.3))
                    }
                    .disabled(selectedCapacity <= 1)
                    
                    Spacer()
                    
                    VStack(spacing: 4) {
                        Text("\(selectedCapacity)")
                            .font(.system(size: 48, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundStyle(Color.accentColor)
                        
                        Text("patients per hour")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        if selectedCapacity < 20 {
                            selectedCapacity += 1
                            hapticFeedback()
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(selectedCapacity < 20 ? Color.accentColor : Color.gray.opacity(0.3))
                    }
                    .disabled(selectedCapacity >= 20)
                }
                .padding(.horizontal, 20)
                
                if slot.currentBookings > 0 {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(.orange)
                        Text("Currently \(slot.currentBookings) patients booked")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.orange.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
            
            Button(action: {
                onSave(selectedCapacity)
                dismiss()
                hapticSuccess()
            }) {
                Text("Update Capacity")
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.accentColor.gradient)
                    )
            }
            .disabled(selectedCapacity == slot.maxCapacity)
            .opacity(selectedCapacity == slot.maxCapacity ? 0.5 : 1.0)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    
    private var timeText: String {
        // slot.startTime is already a String in "HH:mm:ss" format
        let components = slot.startTime.split(separator: ":").map(String.init)
        guard components.count >= 2,
              let hour = Int(components[0]),
              let minute = Int(components[1]) else {
            return slot.startTime
        }
        
        let isPM = hour >= 12
        let displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour)
        let period = isPM ? "PM" : "AM"
        let minuteStr = String(format: "%02d", minute)
        
        return "\(displayHour):\(minuteStr) \(period)"
    }
    
    private func hapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    private func hapticSuccess() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}
