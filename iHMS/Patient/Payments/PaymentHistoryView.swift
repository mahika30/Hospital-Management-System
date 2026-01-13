//
//  PaymentHistoryView.swift
//  iHMS
//
//  Created by Navdeep Singh on 13/01/26.
//

import Foundation
import SwiftUI

struct PaymentHistoryView: View {

    @StateObject private var viewModel = PaymentHistoryViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading payments...")
                }
                else if viewModel.payments.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "creditcard")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)

                        Text("No payments found")
                            .foregroundStyle(.secondary)
                    }
                }
                else {
                    List(viewModel.payments) { payment in
                        PaymentRow(payment: payment)
                    }
                }
            }
            .navigationTitle("Payment History")
            .task {
                await viewModel.loadPayments()
            }
        }
    }
}
