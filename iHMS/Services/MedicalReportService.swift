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

        // 🔍 Validate data
        print("DEBUG: File size: \(fileData.count) bytes")
        guard !fileData.isEmpty else {
            throw MedicalReportError.storageFailed("File data is empty.")
        }
        
        // Use Timestamp + UUID prefix to guarantee uniqueness and safe characters
        let timestamp = Int(Date().timeIntervalSince1970)
        let fileName = "\(timestamp)_\(UUID().uuidString.lowercased()).\(normalizedType)"
        
        // IMPORTANT: Must lowercase the UUID to match Supabase auth.uid()
        // which prevents RLS policy failures in Storage.
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

        // 🔍 Validate data
        guard !fileData.isEmpty else {
            throw MedicalReportError.storageFailed("File data is empty.")
        }

        // 1️⃣ Upload file to Storage
        // REMOVED upsert: true because your RLS policy only allows INSERT, not UPDATE.
        // Overwriting files requires an UPDATE policy.
        print("DEBUG: Starting file upload process.")
        print("DEBUG: Uploading to path: \(filePath)")
        print("DEBUG: User ID: \(userId)")
        
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
            // Include specific error info
            throw MedicalReportError.storageFailed("Storage upload failed: \(error.localizedDescription). Details: \(error)")
        }
        
        // 2️⃣ Insert metadata
        // We use returning: .minimal to avoid "cannot parse response" errors
        // when the SDK tries to decode a response that might be empty or restricted by RLS.
        do {
            try await supabase
                .from("medical_reports")
                .insert([
                    "user_id": userId.uuidString,
                    "uploaded_by": userId.uuidString,
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

    // MARK: Fetch Reports
    func fetchReports(for userId: UUID) async throws -> [MedicalReport] {
        try await supabase
            .from("medical_reports")
            .select()
            .eq("user_id", value: userId.uuidString)
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
            .eq("id", value: report.id.uuidString)
            .execute()

        guard response.status == 200 || response.status == 204 else {
            throw MedicalReportError.deleteFailed
        }
    }
}
