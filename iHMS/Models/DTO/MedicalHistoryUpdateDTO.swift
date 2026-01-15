//
//  MedicalHistoryUpdateDTO.swift
//  iHMS
//
//  Created by Hargun Singh on 15/01/26.
//


struct MedicalHistoryUpdateDTO: Encodable {
    let medical_history: String?
    let allergies: [String]?
    let current_medications: [String]?
}
