import SwiftUI
import UIKit
import UserNotifications

@main
struct SquaredAwayApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        configureAppearance()
        configureNotifications()
        return true
    }

    private func configureAppearance() {
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = UIColor(AppTheme.Colors.backgroundPrimary)
        navBarAppearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        navBarAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.white
        ]
        navBarAppearance.shadowColor = .clear

        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance

        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(AppTheme.Colors.backgroundSecondary)
        UITabBar.appearance().standardAppearance = tabBarAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }

        UITextField.appearance().tintColor = UIColor(AppTheme.Colors.accentSecondary)
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = UIColor(AppTheme.Colors.accentPrimary)
    }

    private func configureNotifications() {
        ReminderPreferences.registerDefaults()
        NotificationPreferences.registerDefaults()
        UNUserNotificationCenter.current().delegate = self
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .badge]
    }
}
