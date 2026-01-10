//
//  SupabaseManager.swift
//  iHMS
//
//  Created by Hargun Singh on 02/01/26.
//

import Supabase
import Foundation

final class SupabaseManager {
    static let shared = SupabaseManager()
    let client: SupabaseClient

    private init() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        client = SupabaseClient(
            supabaseURL: URL(string: "https://zprsrhcqlxctrfauiypg.supabase.co")!,
            supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpwcnNyaGNxbHhjdHJmYXVpeXBnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjczMTY3ODksImV4cCI6MjA4Mjg5Mjc4OX0.a63luOGJpo1a4Mczfb4Go0XKSLdvQ6bn7x3AqNNu3mg"
        )
    }
}
