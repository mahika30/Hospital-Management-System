//
//  iHMSApp.swift
//  iHMS
//
//  Created by Hargun Singh on 02/01/26.
//

import SwiftUI

@main
struct iHMSApp: App {

    @StateObject private var authVM = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .environmentObject(authVM)
                .onOpenURL { url in
                    Task {
                        // ✅ Centralized Deep Link Handler
                        await authVM.handleDeepLink(url: url)
                    }
                }
                .onAppear {
                    // Temporary Analytics Debug
                    AnalyticsService.shared.debugAnalytics()
                }
        }
    }
}
