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


class AdminDashboardViewModel: ObservableObject {
    @Published var doctorsCount: Int = 0
    @Published var patientsCount: Int = 0
    @Published var appointmentsCount: Int = 0
    private let patientService = PatientService()
    private let appointmentService = AppointmentService()
    @Published var selectedDateRange: DateRange = .week
    @Published var revenueData: [AnalyticsData] = []
    @Published var footfallData: [AnalyticsData] = []
    @Published var appointmentsData: [AnalyticsData] = []

    @Published var recentFeedbacks: [FeedbackItem] = []
    @Published var allFeedbacks: [FeedbackItem] = []
    
    init() {
        Task {
            await fetchDashboardStats()
        }
        loadMockAnalytics()
    }
    
    func fetchDashboardStats() async {
        do {
            async let patients = patientService.fetchTotalPatients()
            async let appointments = appointmentService.fetchTotalAppointments()
            
            let (pCount, aCount) = try await (patients, appointments)
            
            await MainActor.run {
                self.patientsCount = pCount
                self.appointmentsCount = aCount
            }
        } catch {
            print("Error fetching dashboard stats: \(error)")
        }
    }
    
    func loadMockAnalytics() {
    
        generateAnalyticsData()
        generateFeedbackData()
    }
    
    func generateAnalyticsData() {
    }
    
    func generateFeedbackData() {

    }
    
    func updateAnalytics(range: DateRange) {
        generateAnalyticsData()
    }
}
