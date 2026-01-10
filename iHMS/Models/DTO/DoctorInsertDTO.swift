//
//  DoctorInsertDTO.swift
//  iHMS
//
//  Created by Hargun Singh on 06/01/26.
//

import Foundation

struct DoctorInsertDTO: Encodable {
    let id: String
    let full_name: String
    let email: String
    let role: String
    let is_active: Bool
}
