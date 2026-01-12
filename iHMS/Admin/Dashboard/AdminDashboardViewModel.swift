//
//  AdminDashboardViewModel.swift
//  iHMS
//
//  Created by Hargun Singh on 07/01/26.
//


import Foundation
import SwiftUI

import Combine
import Foundation

enum DateRange: String, CaseIterable, Identifiable {
    case today = "Today"
    case week = "Last 7 Days"
    case month = "Last 30 Days"
    
    var id: String { rawValue }
}

struct StatItem: Identifiable {
    let id = UUID()
    let title: String
    let value: Int
    let iconName: String
}

struct AnalyticsData: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct FeedbackItem: Identifiable {
    let id = UUID()
    let userName: String
    let feedbackText: String
    let rating: Int
    let date: Date
}


enum StatsTimeRange: String, CaseIterable, Identifiable {
    case today = "Today"
    case week = "This Week"
    
    var id: String { rawValue }
}

class AdminDashboardViewModel: ObservableObject {
    @Published var doctorsCount: Int = 0
    @Published var patientsCount: Int = 0
    @Published var appointmentsCount: Int = 0
    
    @Published var patientsDelta: String = "+0%"
    @Published var appointmentsDelta: String = "+0%"
    
    @Published var statsTimeRange: StatsTimeRange = .week {
        didSet {
            Task { await fetchDashboardStats() }
        }
    }
    
    // Services
    private let patientService = PatientService()
    private let appointmentService = AppointmentService()
    
    // Analytics
    @Published var selectedDateRange: DateRange = .week
    @Published var revenueData: [AnalyticsData] = []
    @Published var footfallData: [AnalyticsData] = []
    @Published var appointmentsData: [AnalyticsData] = []
    
    // Feedback
    @Published var recentFeedbacks: [FeedbackItem] = []
    @Published var allFeedbacks: [FeedbackItem] = []
    
    init() {
        Task {
            await fetchDashboardStats()
        }
        loadMockAnalytics()
    }
    
    @MainActor
    func fetchDashboardStats() async {
        do {
            let (currentRange, previousRange) = getDateRanges(for: statsTimeRange)
            
            // Fetch Current Period Counts
            async let currentPatients = patientService.fetchPatientsCount(from: currentRange.start, to: currentRange.end)
            async let currentAppointments = appointmentService.fetchAppointmentsCount(from: currentRange.start, to: currentRange.end)
            
            // Fetch Previous Period Counts (for Comparison)
            async let previousPatients = patientService.fetchPatientsCount(from: previousRange.start, to: previousRange.end)
            async let previousAppointments = appointmentService.fetchAppointmentsCount(from: previousRange.start, to: previousRange.end)
            
            // Await calculations
            let (currP, currA, prevP, prevA) = try await (currentPatients, currentAppointments, previousPatients, previousAppointments)
            
            self.patientsCount = currP
            self.appointmentsCount = currA
            
            self.patientsDelta = calculatePercentageChange(current: currP, previous: prevP)
            self.appointmentsDelta = calculatePercentageChange(current: currA, previous: prevA)
            
        } catch {
            print("Error fetching dashboard stats: \(error)")
        }
    }
    
    private func getDateRanges(for range: StatsTimeRange) -> (current: (start: Date, end: Date), previous: (start: Date, end: Date)) {
        let calendar = Calendar.current
        let now = Date()
        
        switch range {
        case .today:
            let startOfToday = calendar.startOfDay(for: now)
            let endOfToday = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: now) ?? now
            
            let startOfYesterday = calendar.date(byAdding: .day, value: -1, to: startOfToday)!
            let endOfYesterday = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: startOfYesterday)!
            
            return ((startOfToday, endOfToday), (startOfYesterday, endOfYesterday))
            
        case .week:
            // "This Week" (Start of week to Now) vs "Last Week" (Start of last week to End of last week)
            // Or simple Last 7 Days vs Previous 7 Days?
            // User implementation request: "this week compares with previous week" implies standard calendar weeks usually, but "rolling 7 days" is often better for stats.
            // Let's stick to "Last 7 Days" logic for robustness unless "Monday-Sunday" is preferred.
            // Actually, "This Week" usually means Monday/Sunday to Now.
            // Let's use Calendar Week (Sunday/Monday start)
            
            // Let's use "Last 7 Days" vs "Prior 7 Days" for smoother data if user just started.
            // BUT user said "This Week". Let's try Calendar Week.
            // Actually, to ensure data visibility, a rolling 7 days is safer for a demo.
            // But strict "This Week" is:
            let startOfWeek = calendar.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: now).date!
            let endOfWeek = now // Up to now
            
            let startOfLastWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: startOfWeek)!
            let endOfLastWeek = calendar.date(byAdding: .day, value: 6, to: startOfLastWeek)! // Full previous week
            
            return ((startOfWeek, endOfWeek), (startOfLastWeek, endOfLastWeek))
        }
    }
    
    private func calculatePercentageChange(current: Int, previous: Int) -> String {
        if previous == 0 {
            return current > 0 ? "+100%" : "0%"
        }
        
        let change = Double(current - previous) / Double(previous) * 100.0
        let sign = change >= 0 ? "+" : ""
        return String(format: "%@%.0f%%", sign, change)
    }
    
    func loadMockAnalytics() {
        generateAnalyticsData()
        generateFeedbackData()
    }
    
    func generateAnalyticsData() {
        let calendar = Calendar.current
        let today = Date()
        
        var newRevenue: [AnalyticsData] = []
        var newFootfall: [AnalyticsData] = []
        
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                newRevenue.append(AnalyticsData(date: date, value: Double.random(in: 1000...5000)))
                newFootfall.append(AnalyticsData(date: date, value: Double.random(in: 20...100)))
            }
        }
        
        revenueData = newRevenue.sorted(by: { $0.date < $1.date })
        footfallData = newFootfall.sorted(by: { $0.date < $1.date })
    }
    
    func generateFeedbackData() {
        let names = ["Alice Johnson", "Bob Smith", "Charlie Brown", "Diana Prince", "Evan Wright"]
        let comments = [
            "Great service, very polite staff.",
            "Waiting time was a bit long.",
            "Doctor was extremely helpful explaining things.",
            "Clean facilities and good vibes.",
            "App appointment system is smooth."
        ]
        
        var generated: [FeedbackItem] = []
        for i in 0..<20 {
            let item = FeedbackItem(
                userName: names[i % names.count],
                feedbackText: comments[i % comments.count],
                rating: Int.random(in: 3...5),
                date: Date()
            )
            generated.append(item)
        }
        
        allFeedbacks = generated
        recentFeedbacks = Array(generated.prefix(3))
    }
    
    func updateAnalytics(range: DateRange) {
        generateAnalyticsData()
    }
}
