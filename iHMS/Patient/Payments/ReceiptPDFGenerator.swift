//
//  ReceiptPDFGenerator.swift
//  iHMS
//
//  Created by Navdeep Singh on 13/01/26.
//

import Foundation
import UIKit

final class ReceiptPDFGenerator {

    static func generate(receipt: PaymentReceipt) -> URL {

        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842) // A4
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Receipt-\(receipt.transactionId).pdf")

        do {
            try renderer.writePDF(to: url) { context in
                context.beginPage()

                let titleFont = UIFont.boldSystemFont(ofSize: 22)
                let bodyFont = UIFont.systemFont(ofSize: 14)

                func draw(_ text: String, y: CGFloat, bold: Bool = false) {
                    let attributes: [NSAttributedString.Key: Any] = [
                        .font: bold ? titleFont : bodyFont
                    ]
                    text.draw(
                        at: CGPoint(x: 40, y: y),
                        withAttributes: attributes
                    )
                }

                draw("Payment Receipt", y: 40, bold: true)

                var y: CGFloat = 100
                draw("Hospital: \(receipt.hospitalName)", y: y); y += 30
                draw("Patient: \(receipt.patientName)", y: y); y += 30
                draw("Amount: ₹\(receipt.amount)", y: y); y += 30
                draw("Status: \(receipt.status.capitalized)", y: y); y += 30
                draw("Payment Method: \(receipt.paymentMethod.uppercased())", y: y); y += 30
                draw("Transaction ID: \(receipt.transactionId)", y: y); y += 30

                draw(
                    "Date: " +
                    DateFormatter.localizedString(
                        from: receipt.createdAt,
                        dateStyle: .medium,
                        timeStyle: .short
                    ),
                    y: y
                )

                draw("Thank you for choosing iHMS", y: y + 60)
            }
        } catch {
            print("❌ PDF generation failed:", error)
        }

        return url
    }
}
