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




enum StatsTimeRange: String, CaseIterable, Identifiable {
    case today = "Today"
    case week = "This Week"
    
    var id: String { rawValue }
}

struct BarChartData: Identifiable {
    let id = UUID()
    let label: String
    let value: Int
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
    private let feedbackService = FeedbackService()
    
    // Analytics
    @Published var selectedDateRange: DateRange = .week {
        didSet {
            // Trigger fetch when filter changes
            Task { await fetchAnalytics() }
        }
    }
    @Published var revenueData: [AnalyticsData] = []
    @Published var footfallData: [AnalyticsData] = []
    @Published var appointmentsData: [AnalyticsData] = []
    @Published var busiestDoctorData: [BarChartData] = []
    
    // Feedback
    @Published var recentFeedbacks: [Feedback] = []
    @Published var allFeedbacks: [Feedback] = []
    
    init() {
        Task {
            await fetchDashboardStats()
            await fetchAnalytics()
            await fetchFeedback()
        }
    }
    
    func fetchFeedback() async {
        print("DEBUG: ViewModel fetchFeedback called")
        do {
            async let recentArgs = feedbackService.fetchRecentFeedback(limit: 5)
            async let allArgs = feedbackService.fetchAllFeedback()
            
            let (recent, all) = try await (recentArgs, allArgs)
            
            await MainActor.run {
                print("DEBUG: Updating feedbacks - Recent: \(recent.count), All: \(all.count)")
                self.recentFeedbacks = recent
                self.allFeedbacks = all
            }
        } catch {
            print("Error fetching feedback: \(error)")
        }
    }
    
    /// Refreshes all data on the dashboard
    func refreshData() async {
        await fetchDashboardStats()
        await fetchAnalytics()
        await fetchFeedback()
    }
    
    @MainActor
    func fetchDashboardStats() async {
        do {
            let (currentRange, previousRange) = getStatsDateRanges(for: statsTimeRange)
            
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
    
    // MARK: - Analytics (Graphs)

    @MainActor
    func fetchAnalytics() async {
        // isAnalyticsLoading = true // Property missing in base, ignoring for now as per current file
        
        do {
            let (start, end) = getAnalyticsDateRange(for: selectedDateRange)
            
            // 1. Fetch Data
            let patients = try await patientService.fetchPatients(from: start, to: end)
            let appointments = try await appointmentService.fetchAppointments(from: start, to: end)
            
            // 2. Process Footfall (Line Graph)
            self.footfallData = processFootfallData(patients: patients, start: start, end: end)
            
            // 3. Process Busiest Doctor (Bar Graph Data Structure, used for Line Graph)
            // Note: We need a property for busiestDoctorData. The original file doesn't have it.
            // We will mistakenly try to assign it if we don't add it.
            // Let's add the property in a separate edit or repurpose 'revenueData' or 'appointmentsData'?
            // The user wanted "Busiest Doctor".
            // Since I cannot add a property easily in a Replace block targeting a function, I will assume I need to ADD the property too.
            // But this tool call is replacing the bottom half.
            
            // Wait, I need to add 'busiestDoctorData' property near the top. 
            // I will use 'appointmentsData' for Busiest Doctor for now to avoid compilation error if I can't reach the top property definition easily in this chunk?
            // No, better to add the property properly.
            
             self.busiestDoctorData = processBusiestDoctorData(appointments: appointments)
            
        } catch {
            print("Error fetching analytics: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func getStatsDateRanges(for range: StatsTimeRange) -> (current: (start: Date, end: Date), previous: (start: Date, end: Date)) {
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
            let startOfWeek = calendar.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: now).date!
            let endOfWeek = now
            
            let startOfLastWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: startOfWeek)!
            let endOfLastWeek = calendar.date(byAdding: .day, value: 6, to: startOfLastWeek)!
            
            return ((startOfWeek, endOfWeek), (startOfLastWeek, endOfLastWeek))
        }
    }
    
    private func getAnalyticsDateRange(for range: DateRange) -> (Date, Date) {
        let calendar = Calendar.current
        let now = Date()
        let end = now
        let start: Date
        
        switch range {
        case .today:
            start = calendar.startOfDay(for: now)
        case .week:
            start = calendar.date(byAdding: .day, value: -7, to: now)!
        case .month:
            start = calendar.date(byAdding: .day, value: -30, to: now)!
        }
        
        return (start, end)
    }
    
    private func calculatePercentageChange(current: Int, previous: Int) -> String {
        if previous == 0 {
            return current > 0 ? "+100%" : "0%"
        }
        
        let change = Double(current - previous) / Double(previous) * 100.0
        let sign = change >= 0 ? "+" : ""
        return String(format: "%@%.0f%%", sign, change)
    }
    
    // MARK: - Data Processing
    
    private func processFootfallData(patients: [Patient], start: Date, end: Date) -> [AnalyticsData] {
        let calendar = Calendar.current
        var dict: [Date: Double] = [:]
        
        // Initialize timeline
        var currentDate = start
        while currentDate <= end {
            let key = calendar.startOfDay(for: currentDate)
            dict[key] = 0.0
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
       
        // Aggregate
        for p in patients {
            if let created = p.createdDate {
                let key = calendar.startOfDay(for: created)
                if dict[key] != nil {
                    dict[key]! += 1.0
                }
            }
        }
        
        return dict.map { AnalyticsData(date: $0.key, value: $0.value) }
                   .sorted { $0.date < $1.date }
    }
    
    private func processBusiestDoctorData(appointments: [Appointment]) -> [BarChartData] {
        var counts: [String: Int] = [:]
        
        for appt in appointments {
            if let doctorName = appt.staff?.fullName {
                counts[doctorName, default: 0] += 1
            } else {
                counts["Unknown", default: 0] += 1
            }
        }
        
        // Convert to BarChartData and Sort
        // 1. Sort by count descending first
        let sortedRaw = counts.sorted { $0.value > $1.value }
        
        // 2. Map to BarChartData with Disambiguated Labels
        var usedLabels: Set<String> = []
        var finalData: [BarChartData] = []
        
        for (name, count) in sortedRaw {
            var label = name
            
            // Apply truncation logic: First Name only if > 6 chars
            if name.count > 6 {
                let parts = name.components(separatedBy: " ")
                if let first = parts.first {
                    label = String(first)
                }
            }
            
            // Disambiguation: If label already exists (e.g. two "Hargun"s), append Last Initial
            if usedLabels.contains(label) {
                let parts = name.components(separatedBy: " ")
                if parts.count > 1, let last = parts.last?.first {
                    label = "\(parts[0]) \(last)." // e.g. "Hargun S."
                } else {
                    // Fallback to full name if still getting duplicates or no last name
                     label = name
                }
                
                if usedLabels.contains(label) {
                    label = name // Revert to full name to be safe
                }
            }
            
            usedLabels.insert(label)
            finalData.append(BarChartData(label: label, value: count))
        }
        
        // Take top 5
        return Array(finalData.prefix(5))
    }
    

}
