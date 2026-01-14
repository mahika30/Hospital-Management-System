//
//  SiriShortcuts.swift
//  iHMS
//
//  Created by Hargun Singh on 05/01/26.
// 

import AppIntents
import Foundation

@available(iOS 16.0, *)
struct HMSAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: BookAppointmentIntent(),
            phrases: [
                "Book an appointment in \(.applicationName)",
                "Schedule a doctor visit in \(.applicationName)",
                "Make an appointment in \(.applicationName)"
            ],
            shortTitle: "Book Appointment",
            systemImageName: "calendar.badge.plus"
        )
        
        AppShortcut(
            intent: RescheduleAppointmentIntent(),
            phrases: [
                "Reschedule my appointment in \(.applicationName)",
                "Change my appointment in \(.applicationName)"
            ],
            shortTitle: "Reschedule Appointment",
            systemImageName: "calendar.badge.clock"
        )
        
        AppShortcut(
            intent: CheckAppointmentStatusIntent(),
            phrases: [
                "Check my appointment status in \(.applicationName)",
                "Show my appointments in \(.applicationName)",
                "What is my appointment status in \(.applicationName)?"
            ],
            shortTitle: "Check Status",
            systemImageName: "list.clipboard"
        )
        
        AppShortcut(
            intent: AppointmentReminderIntent(),
            phrases: [
                "Remind me about my appointment in \(.applicationName)",
                "Set appointment reminder in \(.applicationName)"
            ],
            shortTitle: "Set Reminder",
            systemImageName: "bell.fill"
        )
    }
}
