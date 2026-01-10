//
//  Staff.swift
//  iHMS
//
//  Created by Hargun Singh on 06/01/26.
//

import Foundation

struct Staff: Identifiable, Codable {
    let id: UUID
    let fullName: String
    let email: String
    let departmentId: String?
    let designation: String?
    let phone: String?
    let createdAt: String?
    
    // Availability Management Extensions
    var specialization: String?
    var slotCapacity: Int?
    var profileImage: String?
    var isActive: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case fullName = "full_name"
        case email
        case departmentId = "department_id"
        case designation
        case phone
        case createdAt = "created_at"
        case specialization
        case slotCapacity = "slot_capacity"
        case profileImage = "profile_image"
        case isActive = "is_active"
    }
}
