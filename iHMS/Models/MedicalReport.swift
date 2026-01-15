//
//  MedicalReport.swift
//  iHMS
//
//  Created by Hargun Singh on 15/01/26.
//


import Foundation

struct MedicalReport: Codable, Identifiable {

    let id: UUID
    let userId: UUID
    let uploadedBy: UUID
    let doctorId: UUID?
    let filePath: String
    let fileType: String
    let title: String
    let description: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case uploadedBy = "uploaded_by"
        case doctorId = "doctor_id"
        case filePath = "file_path"
        case fileType = "file_type"
        case title
        case description
        case createdAt = "created_at"
    }
}

enum MedicalReportError: LocalizedError {
    case invalidFileType
    case fileTooLarge
    case deleteFailed

    var errorDescription: String? {
        switch self {
        case .invalidFileType:
            return "Only PDF and image files are allowed."
        case .fileTooLarge:
            return "File size exceeds the allowed limit."
        case .deleteFailed:
            return "Failed to delete medical report."
        }
    }
}
