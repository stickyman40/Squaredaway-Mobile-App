import SwiftUI

struct NotificationsView: View {
    @EnvironmentObject private var authVM: AuthViewModel

    @State private var notifications: [AppNotification] = []
    @State private var selectedCategory: NotificationFilter = .all
    @State private var showUnreadOnly = false
    @State private var showClearConfirmation = false
    @State private var pendingClearSection: NotificationSection?
    @State private var pendingDeleteNotification: AppNotification?
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
                    } else if filteredNotifications.isEmpty {
                        filteredEmptyStateCard
                    } else {
                        notificationsList
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.lg)
            }
        }
        .navigationTitle("Notifications")
        .confirmationDialog(
            clearConfirmationTitle,
            isPresented: $showClearConfirmation,
            titleVisibility: .visible
        ) {
            Button(clearButtonTitle, role: .destructive) {
                Task { await clearVisibleNotifications() }
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text(clearConfirmationMessage)
        }
        .confirmationDialog(
            "Delete notification?",
            isPresented: pendingDeleteDialogBinding,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let notification = pendingDeleteNotification {
                    Task { await deleteNotification(notification) }
                }
            }

            Button("Cancel", role: .cancel) {
                pendingDeleteNotification = nil
            }
        } message: {
            Text(singleDeleteConfirmationMessage)
        }
        .confirmationDialog(
            "Clear section?",
            isPresented: pendingSectionClearDialogBinding,
            titleVisibility: .visible
        ) {
            Button("Clear Section", role: .destructive) {
                if let section = pendingClearSection {
                    Task {
                        await clearNotifications(
                            section.notifications,
                            successText: "\(section.title) notifications cleared."
                        )
                    }
                }
            }

            Button("Cancel", role: .cancel) {
                pendingClearSection = nil
            }
        } message: {
            Text(sectionClearConfirmationMessage)
        }
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

                Text(summaryText)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)

                if !notifications.isEmpty {
                    categoryFilterRow
                }

                if !notifications.isEmpty {
                    SecondaryButton(title: markReadButtonTitle) {
                        Task { await markVisibleAsRead() }
                    }
                    .disabled(isUpdating || visibleUnreadCount == 0)
                    .opacity((isUpdating || visibleUnreadCount == 0) ? 0.5 : 1)

                    SecondaryButton(title: clearButtonTitle) {
                        showClearConfirmation = true
                    }
                    .disabled(isUpdating || filteredNotifications.isEmpty)
                    .opacity((isUpdating || filteredNotifications.isEmpty) ? 0.5 : 1)
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

    private var filteredEmptyStateCard: some View {
        GlassCard(padding: AppTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text("No notifications match this view")
                    .font(AppTheme.Typography.titleSmall)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Text(filteredEmptyStateMessage)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)

                SecondaryButton(title: "Show Everything") {
                    selectedCategory = .all
                    showUnreadOnly = false
                }
            }
        }
    }

    private var notificationsList: some View {
        LazyVStack(spacing: AppTheme.Spacing.md) {
            ForEach(groupedNotifications) { section in
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    HStack(alignment: .center, spacing: AppTheme.Spacing.sm) {
                        Text(section.title)
                            .font(AppTheme.Typography.titleSmall)
                            .foregroundColor(AppTheme.Colors.textPrimary)

                        Spacer()

                        if section.unreadCount > 0 {
                            Button("Mark Section Read") {
                                Task {
                                    await markNotificationsAsRead(
                                        section.notifications.filter { !$0.isRead },
                                        successText: "\(section.title) notifications marked as read."
                                    )
                                }
                            }
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.accentSecondary)
                            .buttonStyle(.plain)
                        }

                        Button("Clear Section") {
                            pendingClearSection = section
                        }
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.error)
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, AppTheme.Spacing.xs)

                    ForEach(section.notifications) { notification in
                        NotificationCard(
                            notification: notification,
                            onMarkRead: {
                                Task { await markAsRead(notification) }
                            },
                            onDelete: {
                                pendingDeleteNotification = notification
                            }
                        )
                    }
                }
            }
        }
    }

    private var unreadCount: Int {
        notifications.filter { !$0.isRead }.count
    }

    private var visibleUnreadCount: Int {
        filteredNotifications.filter { !$0.isRead }.count
    }

    private var summaryText: String {
        if notifications.isEmpty {
            return "All caught up."
        }

        if unreadCount == 0 {
            return "\(notifications.count) notification\(notifications.count == 1 ? "" : "s"), all read."
        }

        return "\(unreadCount) unread of \(notifications.count) total notification\(notifications.count == 1 ? "" : "s")."
    }

    private var markReadButtonTitle: String {
        selectedCategory == .all && !showUnreadOnly
            ? "Mark All Read"
            : "Mark Visible Read"
    }

    private var clearButtonTitle: String {
        selectedCategory == .all && !showUnreadOnly
            ? "Clear Inbox"
            : "Clear Visible"
    }

    private var clearConfirmationTitle: String {
        selectedCategory == .all && !showUnreadOnly
            ? "Clear the entire inbox?"
            : "Clear the visible notifications?"
    }

    private var clearConfirmationMessage: String {
        let count = filteredNotifications.count
        let notificationWord = count == 1 ? "notification" : "notifications"

        if selectedCategory == .all && !showUnreadOnly {
            return "This will permanently delete \(count) \(notificationWord) from your inbox."
        }

        if showUnreadOnly && selectedCategory != .all {
            return "This will permanently delete \(count) unread \(selectedCategory.rawValue) \(notificationWord) from the current view."
        }

        if showUnreadOnly {
            return "This will permanently delete \(count) unread \(notificationWord) from the current view."
        }

        return "This will permanently delete \(count) filtered \(notificationWord) from the current view."
    }

    private var filteredNotifications: [AppNotification] {
        notifications.filter { notification in
            selectedCategory.matches(notification) && (!showUnreadOnly || !notification.isRead)
        }
    }

    private var groupedNotifications: [NotificationSection] {
        let calendar = Calendar.current
        let now = Date()

        let grouped = Dictionary(grouping: filteredNotifications) { notification in
            if calendar.isDateInToday(notification.createdAt) {
                return "Today"
            }

            if calendar.isDateInYesterday(notification.createdAt) {
                return "Yesterday"
            }

            if let weekAgo = calendar.date(byAdding: .day, value: -7, to: now),
               notification.createdAt >= weekAgo {
                return "Earlier This Week"
            }

            return "Earlier"
        }

        let order = ["Today", "Yesterday", "Earlier This Week", "Earlier"]
        return order.compactMap { title in
            guard let notifications = grouped[title], !notifications.isEmpty else { return nil }
            return NotificationSection(title: title, notifications: notifications)
        }
    }

    private var filteredEmptyStateMessage: String {
        if showUnreadOnly && selectedCategory != .all {
            return "Try turning off unread-only or switching back to All categories."
        }

        if showUnreadOnly {
            return "Everything in your inbox is already marked as read."
        }

        return "Try a different category filter to see more inbox items."
    }

    private var pendingDeleteDialogBinding: Binding<Bool> {
        Binding(
            get: { pendingDeleteNotification != nil },
            set: { isPresented in
                if !isPresented {
                    pendingDeleteNotification = nil
                }
            }
        )
    }

    private var pendingSectionClearDialogBinding: Binding<Bool> {
        Binding(
            get: { pendingClearSection != nil },
            set: { isPresented in
                if !isPresented {
                    pendingClearSection = nil
                }
            }
        )
    }

    private var singleDeleteConfirmationMessage: String {
        guard let notification = pendingDeleteNotification else {
            return "This notification will be permanently deleted."
        }

        return "Delete \"\(notification.title)\" from your inbox? This action cannot be undone."
    }

    private var sectionClearConfirmationMessage: String {
        guard let section = pendingClearSection else {
            return "These notifications will be permanently deleted."
        }

        let count = section.notifications.count
        let notificationWord = count == 1 ? "notification" : "notifications"
        return "Delete \(count) \(notificationWord) from the \(section.title) section? This action cannot be undone."
    }

    private var categoryFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.Spacing.sm) {
                ForEach(NotificationFilter.allCases) { filter in
                    Button {
                        selectedCategory = filter
                    } label: {
                        Text(filter.label(with: notifications))
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(selectedCategory == filter ? .white : AppTheme.Colors.textSecondary)
                            .padding(.horizontal, AppTheme.Spacing.md)
                            .padding(.vertical, AppTheme.Spacing.sm)
                            .background(
                                Capsule()
                                    .fill(selectedCategory == filter ? AppTheme.Colors.accentPrimary : AppTheme.Colors.backgroundCard)
                            )
                            .overlay(
                                Capsule()
                                    .stroke(
                                        selectedCategory == filter ? AppTheme.Colors.accentPrimary : AppTheme.Colors.glassBorder,
                                        lineWidth: 1
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    showUnreadOnly.toggle()
                } label: {
                    Text(showUnreadOnly ? "Unread Only On" : "Unread Only")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(showUnreadOnly ? .white : AppTheme.Colors.textSecondary)
                        .padding(.horizontal, AppTheme.Spacing.md)
                        .padding(.vertical, AppTheme.Spacing.sm)
                        .background(
                            Capsule()
                                .fill(showUnreadOnly ? AppTheme.Colors.accentSecondary : AppTheme.Colors.backgroundCard)
                        )
                        .overlay(
                            Capsule()
                                .stroke(
                                    showUnreadOnly ? AppTheme.Colors.accentSecondary : AppTheme.Colors.glassBorder,
                                    lineWidth: 1
                                )
                        )
                }
                .buttonStyle(.plain)
            }
        }
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

    private func markVisibleAsRead() async {
        guard !filteredNotifications.isEmpty, visibleUnreadCount > 0 else { return }

        await markNotificationsAsRead(
            filteredNotifications.filter { !$0.isRead },
            successText: selectedCategory == .all && !showUnreadOnly
                ? "All notifications marked as read."
                : "Visible notifications marked as read."
        )
    }

    private func markNotificationsAsRead(_ targetNotifications: [AppNotification], successText: String) async {
        guard !targetNotifications.isEmpty else { return }

        isUpdating = true
        errorMessage = nil
        successMessage = nil
        defer { isUpdating = false }

        do {
            for notification in targetNotifications {
                try await notificationService.markAsRead(id: notification.id)
            }

            let visibleIDs = Set(targetNotifications.map(\.id))
            notifications = notifications.map { notification in
                guard visibleIDs.contains(notification.id) else { return notification }

                var updated = notification
                updated.isRead = true
                return updated
            }

            self.successMessage = successText
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
            pendingDeleteNotification = nil
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

    private func clearVisibleNotifications() async {
        guard !filteredNotifications.isEmpty else { return }

        await clearNotifications(
            filteredNotifications,
            successText: selectedCategory == .all && !showUnreadOnly
                ? "Inbox cleared."
                : "Visible notifications cleared."
        )
    }

    private func clearNotifications(_ targetNotifications: [AppNotification], successText: String) async {
        guard !targetNotifications.isEmpty else { return }

        isUpdating = true
        errorMessage = nil
        successMessage = nil
        defer { isUpdating = false }

        do {
            for notification in targetNotifications {
                try await notificationService.deleteNotification(id: notification.id)
            }

            let visibleIDs = Set(targetNotifications.map(\.id))
            notifications.removeAll { visibleIDs.contains($0.id) }
            pendingClearSection = nil
            self.successMessage = successText
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct NotificationSection: Identifiable {
    let title: String
    let notifications: [AppNotification]

    var id: String { title }
    var unreadCount: Int { notifications.filter { !$0.isRead }.count }
}

private enum NotificationFilter: String, CaseIterable, Identifiable {
    case all
    case milestones
    case readiness
    case activity

    var id: String { rawValue }

    func label(with notifications: [AppNotification]) -> String {
        let count = notifications.filter { matches($0) }.count

        switch self {
        case .all:
            return count == 0 ? "All" : "All (\(count))"
        case .milestones:
            return count == 0 ? "Milestones" : "Milestones (\(count))"
        case .readiness:
            return count == 0 ? "Readiness" : "Readiness (\(count))"
        case .activity:
            return count == 0 ? "Activity" : "Activity (\(count))"
        }
    }

    func matches(_ notification: AppNotification) -> Bool {
        switch self {
        case .all:
            return true
        case .milestones:
            return notification.type == AppNotificationCategory.milestones.rawValue
        case .readiness:
            return notification.type == AppNotificationCategory.readiness.rawValue
        case .activity:
            return notification.type == AppNotificationCategory.activity.rawValue
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
                        HStack(spacing: AppTheme.Spacing.xs) {
                            if let category = category {
                                NotificationCategoryBadge(category: category)
                            }

                            Text(relativeDate(notification.createdAt))
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.Colors.textTertiary)
                        }

                        Text(notification.title)
                            .font(AppTheme.Typography.titleSmall)
                            .foregroundColor(AppTheme.Colors.textPrimary)
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

    private var category: AppNotificationCategory? {
        AppNotificationCategory.from(type: notification.type)
    }

    private func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

private struct NotificationCategoryBadge: View {
    let category: AppNotificationCategory

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: category.icon)
                .font(.system(size: 10, weight: .semibold))
            Text(category.shortTitle)
                .font(AppTheme.Typography.caption)
        }
        .foregroundColor(tintColor)
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, 6)
        .background(tintColor.opacity(0.12))
        .overlay(
            Capsule()
                .stroke(tintColor.opacity(0.25), lineWidth: 1)
        )
        .cornerRadius(AppTheme.Radius.full)
    }

    private var tintColor: Color {
        switch category {
        case .milestones:
            return AppTheme.Colors.accentSecondary
        case .readiness:
            return AppTheme.Colors.accentPrimary
        case .activity:
            return AppTheme.Colors.success
        }
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
