//
//  ProfileDTO.swift
//  iHMS
//
//  Created by Hargun Singh on 06/01/26.
//


import Foundation
struct ProfileInsertDTO: Encodable {
    let id: String
    let full_name: String
    let email: String
    let role: String
    let is_active: Bool
    let has_set_password: Bool 
}

struct ProfileDTO: Decodable {
    let role: String
    let is_active: Bool
    let has_set_password: Bool
}
struct ProfileNameDTO: Decodable {
    let full_name: String
}

