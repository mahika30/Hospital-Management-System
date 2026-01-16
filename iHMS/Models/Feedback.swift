import Foundation

struct Feedback: Identifiable, Codable {
    let id: UUID
    let patientId: UUID
    let rating: Int
    let comments: String?
    let createdAt: String
    
    // Relations
    struct FeedbackPatient: Codable {
        let fullName: String
        
        enum CodingKeys: String, CodingKey {
            case fullName = "full_name"
        }
    }
    
    var patient: FeedbackPatient?
    
    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case rating
        case comments
        case createdAt = "created_at"
        case patient = "patients"
    }
    
    var createdDate: Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: createdAt) ?? Date()
    }
}
