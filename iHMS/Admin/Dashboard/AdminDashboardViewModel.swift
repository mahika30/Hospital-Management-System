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
    
    // Analytics
    @Published var selectedDateRange: DateRange = .week
    @Published var revenueData: [AnalyticsData] = []
    @Published var footfallData: [AnalyticsData] = []
    @Published var appointmentsData: [AnalyticsData] = []
    
    // Feedback
    @Published var recentFeedbacks: [FeedbackItem] = []
    @Published var allFeedbacks: [FeedbackItem] = []
    
    init() {
        loadMockData()
    }
    
    func loadMockData() {
        doctorsCount = 42
        patientsCount = 1250
        
        generateAnalyticsData()
        generateFeedbackData()
    }
    
    func generateAnalyticsData() {
        // Mock data logic based on date range (simplified for now)
        let calendar = Calendar.current
        let today = Date()
        
        // Generate last 7 days mock data
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
        // In a real app, this would fetch specific data.
        // For mock, just re-randomize to show "update" effect.
        generateAnalyticsData()
    }
}
