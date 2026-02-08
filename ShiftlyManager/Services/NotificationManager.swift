import Foundation
import UserNotifications
import UIKit

@MainActor
final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published var isAuthorized = false

    private init() {}

    func requestPermission() async {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            isAuthorized = granted
            if granted {
                UIApplication.shared.registerForRemoteNotifications()
            }
        } catch {
            print("Notification permission error: \(error)")
        }
    }

    func scheduleLocalEscalationAlert(phone: String, reason: String) {
        let content = UNMutableNotificationContent()
        content.title = "🚨 Escalation"
        content.body = "\(phone) needs attention: \(reason)"
        content.sound = .default
        content.badge = 1

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0)
    }
}
