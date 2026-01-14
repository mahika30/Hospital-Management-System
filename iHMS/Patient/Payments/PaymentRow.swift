//
//  PaymentRow.swift
//  iHMS
//
//  Created by Navdeep Singh on 13/01/26.
//

import SwiftUI

struct PaymentRow: View {

    let payment: Payment
    let patientName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            HStack {
                Text("₹\(payment.amount)")
                    .font(.headline)

                Spacer()

                Text(payment.status.capitalized)
                    .font(.caption)
                    .foregroundStyle(payment.status == "paid" ? .green : .red)
            }

            // 🩺 CONSULTATION TITLE
            Text("Doctor Consultation")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)

            if let tx = payment.transaction_id {
                Text("Txn ID: \(tx)")
                    .font(.caption)
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

            // ⬇️ DOWNLOAD RECEIPT
            HStack {
                Spacer()

                ShareLink(
                    item: ReceiptPDFGenerator.generate(
                        receipt: PaymentReceipt(
                            hospitalName: "iHMS Hospital",
                            patientName: patientName,
                            amount: payment.amount,
                            status: payment.status,
                            transactionId: payment.transaction_id
                                ?? payment.id.uuidString,
                            paymentMethod: payment.payment_method ?? "upi",
                            createdAt: payment.created_at
                        )
                    ),
                    preview: SharePreview(
                        "Payment Receipt",
                        icon: Image(systemName: "doc.fill")
                    )
                ) {
                    Label("Receipt", systemImage: "arrow.down.doc")
                        .font(.caption)
                }
            }
        }
        .padding(.vertical, 10)

    }
}
