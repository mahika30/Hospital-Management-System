//
//  AnalyticsStaffDTO.swift
//  iHMS
//
//  Created by Hargun Singh on 13/01/26.
//

import Foundation
struct AnalyticsStaffDTO: Codable {
    let id: UUID
    let fullName: String
    let specialization: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case fullName = "full_name"
        case specialization
    }
}
