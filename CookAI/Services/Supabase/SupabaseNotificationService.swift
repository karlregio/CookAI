//
//  SupabaseNotificationService.swift
//  CookAI
//
//  Unread count for the dashboard bell. RLS limits `notifications` to the
//  signed-in user's own rows; guests always see 0.
//

import Foundation
import Supabase

final class SupabaseNotificationService: NotificationService {
    private let client: SupabaseClient

    init(client: SupabaseClient = SupabaseConfig.client) {
        self.client = client
    }

    func fetchUnreadCount() async throws -> Int {
        guard client.auth.currentUser != nil else { return 0 }
        do {
            let response = try await client.from("notifications")
                .select("id", head: true, count: .exact)
                .eq("is_read", value: false)
                .execute()
            return response.count ?? 0
        } catch {
            throw SupabaseServiceError.friendly(error)
        }
    }
}
