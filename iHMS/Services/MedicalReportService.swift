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

    // MARK: Configuration
    private let maxFileSizeMB: Double = 5
    private let allowedFileTypes = ["pdf", "jpg", "jpeg", "png"]

    private init() {}

    // MARK: Upload Report (with validation)
    func uploadReport(
        userId: UUID,
        title: String,
        description: String?,
        fileData: Data,
        fileType: String
    ) async throws {

        // 🔍 Validate file type
        let normalizedType = fileType.lowercased()
        guard allowedFileTypes.contains(normalizedType) else {
            throw MedicalReportError.invalidFileType
        }

        // 🔍 Validate file size
        let fileSizeMB = Double(fileData.count) / (1024 * 1024)
        guard fileSizeMB <= maxFileSizeMB else {
            throw MedicalReportError.fileTooLarge
        }

        let fileName = "\(UUID().uuidString).\(normalizedType)"
        let filePath = "\(userId.uuidString)/\(fileName)"

        let contentType: String
        switch normalizedType {
        case "pdf":
            contentType = "application/pdf"
        case "png":
            contentType = "image/png"
        default:
            contentType = "image/jpeg"
        }

        // 1️⃣ Upload file to Storage
        try await supabase.storage
            .from("medical-reports")
            .upload(
                path: filePath,
                file: fileData,
                options: FileOptions(contentType: contentType)
            )

        // 2️⃣ Insert metadata
        try await supabase
            .from("medical_reports")
            .insert([
                "user_id": userId.uuidString,
                "uploaded_by": userId.uuidString,
                "file_path": filePath,
                "file_type": normalizedType,
                "title": title,
                "description": description
            ])
            .execute()
    }

    // MARK: Fetch Reports
    func fetchReports(for userId: UUID) async throws -> [MedicalReport] {
        try await supabase
            .from("medical_reports")
            .select()
            .eq("user_id", userId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
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

    // MARK: Delete Report (DB + Storage)
    func deleteReport(_ report: MedicalReport) async throws {

        // 1️⃣ Delete file from Storage
        try await supabase.storage
            .from("medical-reports")
            .remove(paths: [report.filePath])

        // 2️⃣ Delete metadata from DB
        let response = try await supabase
            .from("medical_reports")
            .delete()
            .eq("id", report.id.uuidString)
            .execute()

        guard response.status == 200 || response.status == 204 else {
            throw MedicalReportError.deleteFailed
        }
    }
}
