//
//  Payment.swift
//  iHMS
//
//  Created by Navdeep Singh on 13/01/26.
//


import Foundation

struct Payment: Identifiable, Decodable {
    let id: UUID
    let patient_id: UUID
    let amount: Int
    let status: String
    let payment_method: String?
    let transaction_id: String?
    let created_at: Date
}
