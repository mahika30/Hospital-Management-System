//
//  MedicalReport.swift
//  iHMS
//
//  Created by Hargun Singh on 15/01/26.
//


import Foundation
import Supabase

final class MedicalReportService {

    static let shared = MedicalReportService()
    private let supabase = SupabaseManager.shared.client

    private let maxFileSizeMB: Double = 5
    private let allowedFileTypes = ["pdf", "jpg", "jpeg", "png"]

    private init() {}

    func uploadReport(
        userId: UUID,
        uploadedBy: UUID,
        doctorId: UUID?,
        title: String,
        description: String?,
        fileData: Data,
        fileType: String
    ) async throws {

        let normalizedType = fileType.lowercased()
        guard allowedFileTypes.contains(normalizedType) else {
            throw MedicalReportError.invalidFileType
        }

        let fileSizeMB = Double(fileData.count) / (1024 * 1024)
        guard fileSizeMB <= maxFileSizeMB else {
            throw MedicalReportError.fileTooLarge
        }

        print("DEBUG: File size: \(fileData.count) bytes")
        guard !fileData.isEmpty else {
            throw MedicalReportError.storageFailed("File data is empty.")
        }
        
        let timestamp = Int(Date().timeIntervalSince1970)
        let fileName = "\(timestamp)_\(UUID().uuidString.lowercased()).\(normalizedType)"
        
        let filePath = "\(userId.uuidString.lowercased())/\(fileName)"

        let contentType: String
        switch normalizedType {
        case "pdf":
            contentType = "application/pdf"
        case "png":
            contentType = "image/png"
        default:
            contentType = "image/jpeg"
        }

        guard !fileData.isEmpty else {
            throw MedicalReportError.storageFailed("File data is empty.")
        }
        
        do {
            try await supabase.storage
                .from("medical-reports")
                .upload(
                    filePath,
                    data: fileData,
                    options: FileOptions(contentType: contentType)
                )
        } catch {
            print("DEBUG: Storage Error: \(error)")
            throw MedicalReportError.storageFailed("Storage upload failed: \(error.localizedDescription). Details: \(error)")
        }

        do {
            try await supabase
                .from("medical_reports")
                .insert([
                    "user_id": userId.uuidString,
                    "uploaded_by": uploadedBy.uuidString,
                    "doctor_id": doctorId?.uuidString,
                    "file_path": filePath,
                    "file_type": normalizedType,
                    "title": title,
                    "description": description
                ]) // Back to default behavior to test
                .execute()
        } catch {
            throw MedicalReportError.databaseFailed(error.localizedDescription)
        }
    }

    func fetchReports(for userId: UUID) async throws -> [MedicalReport] {
        // 1. Fetch Reports (without nested staff join to avoid FK error)
        var reports: [MedicalReport] = try await supabase
            .from("medical_reports")
            .select() // Select all fields, 'doctor' will be nil initially
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        let doctorIds = reports.compactMap { $0.doctorId }.map { $0.uuidString }
        
        guard !doctorIds.isEmpty else {
            return reports
        }
        
        // 3. Fetch Staff Names
        struct StaffName: Codable {
            let id: UUID
            let fullName: String
            enum CodingKeys: String, CodingKey {
                case id
                case fullName = "full_name"
            }
        }
        
        let doctors: [StaffName] = try await supabase
            .from("staff")
            .select("id, full_name")
            .in("id", values: doctorIds)
            .execute()
            .value
        
        for i in 0..<reports.count {
            if let docId = reports[i].doctorId,
               let match = doctors.first(where: { $0.id == docId }) {
                reports[i].doctor = MedicalReport.PartialStaff(fullName: match.fullName)
            }
        }
        
        return reports
    }

    // MARK: Signed URL
    func getSignedURL(for report: MedicalReport) async throws -> URL {
        try await supabase.storage
            .from("medical-reports")
            .createSignedURL(
                path: report.filePath,
                expiresIn: 3600
            )
    }

    func deleteReport(_ report: MedicalReport, requestingUserId: UUID) async throws {
        
        
        if report.uploadedBy != requestingUserId {

            throw MedicalReportError.deleteFailed
        }

        try await supabase.storage
            .from("medical-reports")
            .remove(paths: [report.filePath])

        let response = try await supabase
            .from("medical_reports")
            .delete()
            .eq("id", value: report.id.uuidString)
            .execute()

        guard response.status == 200 || response.status == 204 else {
            throw MedicalReportError.deleteFailed
        }
    }
}
