//
//  SupabaseConfig.swift
//  CookAI
//
//  The one shared Supabase client for the app. The publishable key is meant
//  to ship inside client apps; the data is protected by Row Level Security in
//  the database (see cookai_schema.sql). Never put the secret key here.
//

import Foundation
import Supabase

enum SupabaseConfig {
    static let url = URL(string: "https://fyqumduufxeyhrwazsji.supabase.co")!
    static let publishableKey = "sb_publishable_IkELxQ1CHct8DZ_KPo5vBg_oYau2l5h"

    static let client = SupabaseClient(supabaseURL: url, supabaseKey: publishableKey)

    /// Profile columns the app may read. `email` is deliberately absent: the
    /// database hides it from everyone except the owner and admins, so
    /// `select()` (= every column) would be refused.
    static let profileColumns = "id, username, display_name, role, avatar_color_hex, bio, is_verified, recipes_count, total_likes"
}

/// User-facing errors shared by the Supabase-backed services.
enum SupabaseServiceError: LocalizedError {
    case signInRequired
    case confirmEmail
    case emailNotConfirmed
    case profileMissing
    case network

    var errorDescription: String? {
        switch self {
        case .signInRequired:
            return "Sign in to do that — guests can browse recipes only."
        case .confirmEmail:
            return "Account created! Check your inbox and tap the confirmation link, then log in."
        case .emailNotConfirmed:
            return "This account's email isn't confirmed yet. Confirm it from the email we sent, then log in."
        case .profileMissing:
            return "We couldn't load your profile. Please try again."
        case .network:
            return "Couldn't reach CookAI. Check your internet connection and try again."
        }
    }

    /// Maps low-level errors (URLError, Supabase errors) to friendly messages.
    static func friendly(_ error: Error) -> Error {
        if error is SupabaseServiceError { return error }
        if error is URLError { return SupabaseServiceError.network }
        return error
    }
}

/// JSON decoding for Supabase responses, done on the main actor.
///
/// This project uses MainActor-by-default isolation, so the models' Codable
/// conformances are main-actor isolated. The SDK's built-in `.value` decodes
/// off the main actor, so we fetch the raw bytes and decode them here instead.
extension PostgrestBuilder {
    func fetch<T: Decodable>(_ type: T.Type = T.self) async throws -> T {
        let response: PostgrestResponse<Void> = try await execute()
        return try SupabaseJSON.decoder.decode(T.self, from: response.data)
    }
}

nonisolated enum SupabaseJSON {
    static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self)
            guard let date = parseDate(raw) else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unrecognized date: \(raw)")
            }
            return date
        }
        return decoder
    }

    /// Parses Postgres timestamps such as "2026-08-01T04:00:00+00:00" or
    /// "2026-11-18T14:12:33.123456+00:00" (fraction trimmed to milliseconds).
    static func parseDate(_ raw: String) -> Date? {
        var value = raw.replacingOccurrences(of: " ", with: "T")
        if let dot = value.firstIndex(of: "."),
           let zoneStart = value[dot...].firstIndex(where: { $0 == "+" || $0 == "-" || $0 == "Z" }) {
            let digits = value[value.index(after: dot)..<zoneStart]
            let millis = String((digits + "000").prefix(3))
            value = String(value[..<dot]) + "." + millis + String(value[zoneStart...])
        }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = value.contains(".")
            ? [.withInternetDateTime, .withFractionalSeconds]
            : [.withInternetDateTime]
        return formatter.date(from: value)
    }
}
