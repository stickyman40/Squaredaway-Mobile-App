import SwiftUI

struct NotificationsView: View {
    @EnvironmentObject private var authVM: AuthViewModel

    @State private var notifications: [AppNotification] = []
    @State private var isLoading = false
    @State private var isUpdating = false
    @State private var errorMessage: String?
    @State private var successMessage: String?

    private let notificationService = NotificationService.shared

    var body: some View {
        ZStack {
            AppTheme.Colors.backgroundPrimary.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                    summaryCard

                    if let errorMessage {
                        NotificationsBanner(
                            message: errorMessage,
                            color: AppTheme.Colors.error,
                            icon: "exclamationmark.triangle.fill"
                        )
                    }

                    if let successMessage {
                        NotificationsBanner(
                            message: successMessage,
                            color: AppTheme.Colors.success,
                            icon: "checkmark.circle.fill"
                        )
                    }

                    if isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(AppTheme.Colors.accentPrimary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, AppTheme.Spacing.xl)
                    } else if notifications.isEmpty {
                        emptyStateCard
                    } else {
                        notificationsList
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.lg)
            }
        }
        .navigationTitle("Notifications")
        .task {
            await loadNotifications()
        }
    }

    private var summaryCard: some View {
        GlassCard(padding: AppTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                Text("Inbox")
                    .font(AppTheme.Typography.titleMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Text(unreadCount == 0 ? "All caught up." : "\(unreadCount) unread notification\(unreadCount == 1 ? "" : "s").")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)

                if !notifications.isEmpty {
                    SecondaryButton(title: "Mark All Read") {
                        Task { await markAllAsRead() }
                    }
                    .disabled(isUpdating || unreadCount == 0)
                    .opacity((isUpdating || unreadCount == 0) ? 0.5 : 1)

                    SecondaryButton(title: "Clear Inbox") {
                        Task { await clearInbox() }
                    }
                    .disabled(isUpdating)
                    .opacity(isUpdating ? 0.5 : 1)
                }

                SecondaryButton(title: "Add Sample Notifications") {
                    Task { await addSampleNotifications() }
                }
                .disabled(isUpdating)
                .opacity(isUpdating ? 0.5 : 1)
            }
        }
    }

    private var emptyStateCard: some View {
        GlassCard(padding: AppTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text("No notifications yet")
                    .font(AppTheme.Typography.titleSmall)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Text("Account alerts and app messages will appear here when available.")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
    }

    private var notificationsList: some View {
        LazyVStack(spacing: AppTheme.Spacing.md) {
            ForEach(notifications) { notification in
                NotificationCard(
                    notification: notification,
                    onMarkRead: {
                        Task { await markAsRead(notification) }
                    },
                    onDelete: {
                        Task { await deleteNotification(notification) }
                    }
                )
            }
        }
    }

    private var unreadCount: Int {
        notifications.filter { !$0.isRead }.count
    }

    private func loadNotifications() async {
        guard let userId = authVM.currentUserId else { return }

        isLoading = true
        errorMessage = nil
        successMessage = nil
        defer { isLoading = false }

        do {
            notifications = try await notificationService.fetchNotifications(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func markAsRead(_ notification: AppNotification) async {
        guard !notification.isRead else { return }

        isUpdating = true
        errorMessage = nil
        successMessage = nil
        defer { isUpdating = false }

        do {
            try await notificationService.markAsRead(id: notification.id)
            if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
                notifications[index].isRead = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func markAllAsRead() async {
        guard let userId = authVM.currentUserId, unreadCount > 0 else { return }

        isUpdating = true
        errorMessage = nil
        successMessage = nil
        defer { isUpdating = false }

        do {
            try await notificationService.markAllAsRead(userId: userId)
            notifications = notifications.map { notification in
                var updated = notification
                updated.isRead = true
                return updated
            }
            successMessage = "All notifications marked as read."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deleteNotification(_ notification: AppNotification) async {
        isUpdating = true
        errorMessage = nil
        successMessage = nil
        defer { isUpdating = false }

        do {
            try await notificationService.deleteNotification(id: notification.id)
            notifications.removeAll { $0.id == notification.id }
            successMessage = "Notification deleted."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func addSampleNotifications() async {
        guard let userId = authVM.currentUserId else { return }

        isUpdating = true
        errorMessage = nil
        successMessage = nil
        defer { isUpdating = false }

        do {
            try await notificationService.seedSampleNotifications(userId: userId)
            notifications = try await notificationService.fetchNotifications(userId: userId)
            successMessage = "Sample notifications added."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func clearInbox() async {
        guard let userId = authVM.currentUserId, !notifications.isEmpty else { return }

        isUpdating = true
        errorMessage = nil
        successMessage = nil
        defer { isUpdating = false }

        do {
            try await notificationService.deleteAllNotifications(userId: userId)
            notifications = []
            successMessage = "Inbox cleared."
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct NotificationCard: View {
    let notification: AppNotification
    let onMarkRead: () -> Void
    let onDelete: () -> Void

    var body: some View {
        GlassCard(padding: AppTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
                    Circle()
                        .fill(notification.isRead ? AppTheme.Colors.textTertiary : AppTheme.Colors.accentPrimary)
                        .frame(width: 10, height: 10)
                        .padding(.top, 6)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(notification.title)
                            .font(AppTheme.Typography.titleSmall)
                            .foregroundColor(AppTheme.Colors.textPrimary)

                        Text(relativeDate(notification.createdAt))
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }

                    Spacer()
                }

                Text(notification.body)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)

                HStack(spacing: AppTheme.Spacing.md) {
                    if !notification.isRead {
                        Button("Mark Read", action: onMarkRead)
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.accentSecondary)
                    }

                    Button("Delete", action: onDelete)
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.error)
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.xl)
                .stroke(notification.isRead ? Color.clear : AppTheme.Colors.accentPrimary.opacity(0.25), lineWidth: 1)
        )
    }

    private func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

private struct NotificationsBanner: View {
    let message: String
    let color: Color
    let icon: String

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(message)
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(color)
            Spacer()
        }
        .padding(AppTheme.Spacing.sm)
        .background(color.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.sm)
                .stroke(color.opacity(0.24), lineWidth: 1)
        )
        .cornerRadius(AppTheme.Radius.sm)
    }
}

#Preview {
    NavigationStack {
        NotificationsView()
            .environmentObject(AuthViewModel())
            .preferredColorScheme(.dark)
    }
}
