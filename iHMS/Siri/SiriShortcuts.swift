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
                AppShortcut(
            intent: DoctorAppointmentCountIntent(),
            phrases: [
                "How many appointments do I have today in \(.applicationName)?",
                "Total appointments for today in \(.applicationName)"
            ],
            shortTitle: "My Appointments",
            systemImageName: "stethoscope"
        )
        AppShortcut(
            intent: DoctorCloseAllSlotsIntent(),
            phrases: [
                "Close all my slots in \(.applicationName)",
                "Close my slots for today in \(.applicationName)",
                "Block my schedule in \(.applicationName)"
            ],
            shortTitle: "Close All Slots",
            systemImageName: "lock.fill"
        )

        AppShortcut(
            intent: DoctorOpenAllSlotsIntent(),
            phrases: [
                "Open all my slots in \(.applicationName)",
                "Open my slots for today in \(.applicationName)",
                "Unblock my schedule in \(.applicationName)"
            ],
            shortTitle: "Open All Slots",
            systemImageName: "lock.open.fill"
        )
        
        AppShortcut(
            intent: DoctorCloseSpecificSlotIntent(),
            phrases: [
                "Close a specific slot in \(.applicationName)",
                "Block a time slot in \(.applicationName)",
                "Manage my slots in \(.applicationName)"
            ],
            shortTitle: "Close Single Slot",
            systemImageName: "clock.badge.xmark.fill"
        )
        
        AppShortcut(
            intent: AdminAnalyticsIntent(),
            phrases: [
                "Admin dashboard summary in \(.applicationName)",
                "Today's hospital analytics in \(.applicationName)"
            ],
            shortTitle: "Admin Dashboard",
            systemImageName: "chart.bar.fill"
        )
    }
}
