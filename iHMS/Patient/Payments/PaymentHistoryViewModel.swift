//
//  PaymentHistoryViewModel.swift
//  iHMS
//
//  Created by Navdeep Singh on 13/01/26.
//

import Foundation
import Supabase
import PostgREST
import Combine

@MainActor
final class PaymentHistoryViewModel: ObservableObject {

    @Published var payments: [Payment] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let supabase = SupabaseManager.shared.client

    func loadPayments() async {
        isLoading = true
        errorMessage = nil

        do {
            let userId = try await supabase.auth.session.user.id

            let result: [Payment] = try await supabase.database
                .from("payments")
                .select()
                .eq("patient_id", value: userId.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value

            payments = result
        } catch {
            errorMessage = "Failed to load payments"
            print("❌ Payment history error:", error)
        }

        isLoading = false
    }
}
