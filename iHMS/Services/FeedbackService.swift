import Foundation
import Supabase

final class FeedbackService {
    
    func fetchRecentFeedback(limit: Int = 5) async throws -> [Feedback] {
        print("DEBUG: Fetching recent feedback...")
        do {
            let feedbacks: [Feedback] = try await SupabaseManager.shared.client
                .from("feedback")
                .select("""
                    *,
                    patients (
                        full_name
                    )
                """)
                .order("created_at", ascending: false)
                .limit(limit)
                .execute()
                .value
            
            print("DEBUG: Successfully fetched \(feedbacks.count) feedbacks")
            return feedbacks
        } catch {
            print("DEBUG: Error fetching feedback: \(error)")
            throw error
        }
    }
    
    func fetchAllFeedback() async throws -> [Feedback] {
        let feedbacks: [Feedback] = try await SupabaseManager.shared.client
            .from("feedback")
            .select("""
                *,
                patients (
                    full_name
                )
            """)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return feedbacks
    }
}
