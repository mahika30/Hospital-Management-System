//
//  PaymentReceipt.swift
//  iHMS
//
//  Created by Navdeep Singh on 13/01/26.
//

import Foundation

struct PaymentReceipt {
    let hospitalName: String
    let patientName: String
    let amount: Int
    let status: String
    let transactionId: String
    let paymentMethod: String
    let createdAt: Date
}
