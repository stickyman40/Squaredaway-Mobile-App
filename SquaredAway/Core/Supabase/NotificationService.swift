import Foundation
import Supabase

final class NotificationService {
    static let shared = NotificationService()

    private init() {}

    private var client: SupabaseClient { SupabaseManager.shared.client }
    private let table = SupabaseManager.Tables.notifications

    func createNotification(
        userId: UUID,
        category: AppNotificationCategory,
        title: String,
        body: String,
        suppressDuplicatesWithin interval: TimeInterval = 0
    ) async throws {
        guard NotificationPreferences.isEnabled(for: category) else {
            return
        }

        if interval > 0, try await hasRecentDuplicate(userId: userId, title: title, body: body, within: interval) {
            return
        }

        let payload = NotificationInsert(
            userId: userId,
            title: title,
            body: body,
            isRead: false
        )

        try await client
            .from(table)
            .insert(payload)
            .execute()
    }

    func fetchNotifications(userId: UUID) async throws -> [AppNotification] {
        try await client
            .from(table)
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    func unreadCount(userId: UUID) async throws -> Int {
        let notifications = try await fetchNotifications(userId: userId)
        return notifications.filter { !$0.isRead }.count
    }

    func markAsRead(id: UUID) async throws {
        try await client
            .from(table)
            .update(["is_read": true])
            .eq("id", value: id.uuidString)
            .execute()
    }

    func markAllAsRead(userId: UUID) async throws {
        try await client
            .from(table)
            .update(["is_read": true])
            .eq("user_id", value: userId.uuidString)
            .eq("is_read", value: false)
            .execute()
    }

    func deleteNotification(id: UUID) async throws {
        try await client
            .from(table)
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    func deleteAllNotifications(userId: UUID) async throws {
        try await client
            .from(table)
            .delete()
            .eq("user_id", value: userId.uuidString)
            .execute()
    }

    func seedSampleNotifications(userId: UUID) async throws {
        let payloads = [
            NotificationInsert(
                userId: userId,
                title: "Welcome to the Inbox",
                body: "This is a sample unread notification for testing the inbox UI.",
                isRead: false
            ),
            NotificationInsert(
                userId: userId,
                title: "Readiness Update",
                body: "Sample promotion, pay, and reminder updates will appear like this.",
                isRead: false
            ),
            NotificationInsert(
                userId: userId,
                title: "Previously Reviewed",
                body: "This sample item starts as read so you can preview both states.",
                isRead: true
            )
        ]

        try await client
            .from(table)
            .insert(payloads)
            .execute()
    }

    func runPipelineProbe() async throws -> NotificationPipelineProbeResult {
        try await client
            .rpc("run_notification_pipeline_probe")
            .execute()
            .value
    }

    private func hasRecentDuplicate(userId: UUID, title: String, body: String, within interval: TimeInterval) async throws -> Bool {
        let recent: [AppNotification] = try await client
            .from(table)
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .limit(10)
            .execute()
            .value

        let cutoffDate = Date().addingTimeInterval(-interval)
        return recent.contains {
            $0.title == title &&
            $0.body == body &&
            $0.createdAt >= cutoffDate
        }
    }
}

private struct NotificationInsert: Encodable {
    let userId: UUID
    let title: String
    let body: String
    let isRead: Bool

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case title
        case body
        case isRead = "is_read"
    }
}

struct NotificationPipelineProbeResult: Decodable {
    let status: String
    let notificationId: UUID?
    let message: String

    enum CodingKeys: String, CodingKey {
        case status
        case notificationId = "notification_id"
        case message
    }
}
