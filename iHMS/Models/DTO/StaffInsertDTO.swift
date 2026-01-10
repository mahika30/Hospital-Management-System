//
//  StaffInsertDTO.swift
//  iHMS
//
//  Created by Hargun Singh on 06/01/26.
//

import Foundation
struct StaffInsertDTO: Encodable {
    let id: String
    let full_name: String
    let email: String
    let department_id: String?
    let designation: String?
    let phone: String?
}
