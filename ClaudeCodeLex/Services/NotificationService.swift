// NotificationService.swift
// Local daily streak reminder via UNUserNotificationCenter.
// Device-only: no backend, no push tokens — purely on-device scheduling.

import Foundation
import UserNotifications

enum NotificationService {
    /// Single repeating request — re-adding with this id replaces the old one.
    private static let dailyReminderID = "agenticlex.daily.reminder"

    /// Ask the user for notification permission. Returns whether it was granted.
    /// If the user previously denied, this returns false without showing a prompt.
    static func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    /// Current system-level authorization status.
    static func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    /// Re-schedule (or cancel) the daily reminder.
    /// Called on toggle, on time change, and on app-active so the body stays
    /// in sync with the current streak count.
    static func reschedule(enabled: Bool, hour: Int, minute: Int, streakDays: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [dailyReminderID])
        guard enabled else { return }

        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("notify.daily.title", comment: "")
        if streakDays > 0 {
            content.body = String(format: NSLocalizedString("notify.daily.body.streak", comment: ""),
                                  streakDays)
        } else {
            content.body = NSLocalizedString("notify.daily.body", comment: "")
        }
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(identifier: dailyReminderID,
                                            content: content,
                                            trigger: trigger)
        center.add(request)
    }
}
