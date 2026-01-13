//
//  PaymentRow.swift
//  iHMS
//
//  Created by Navdeep Singh on 13/01/26.
//

import Foundation
import SwiftUI

struct PaymentRow: View {
    
    let payment: Payment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            
            HStack {
                Text("₹\(payment.amount)")
                    .font(.headline)
                
                Spacer()
                
                Text(payment.status.capitalized)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        payment.status == "paid"
                        ? Color.green.opacity(0.2)
                        : Color.red.opacity(0.2)
                    )
                    .foregroundStyle(payment.status == "paid" ? .green : .red)
                    .cornerRadius(6)
            }
            
            Text("Doctor Consultation")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Text("Paid via \(payment.payment_method?.uppercased())")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            if let tx = payment.transaction_id {
                Text("Txn ID: \(tx)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Text(
                payment.created_at.formatted(
                    date: .abbreviated,
                    time: .shortened
                )
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
        
    }
}
