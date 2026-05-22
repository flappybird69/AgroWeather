import Foundation
import UserNotifications

actor ReminderManager {
    static let shared = ReminderManager()

    func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func scheduleReminder(for entry: FarmLogEntry) async {
        guard let reminderDate = entry.reminderDate, reminderDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "🔔 Υπενθύμιση: \(entry.type.rawValue)"
        if !entry.notes.isEmpty { content.body = entry.notes }
        if let fieldName = entry.fieldName { content.body += " — \(fieldName)" }
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: entry.id.uuidString, content: content, trigger: trigger)

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {}
    }

    func cancelReminder(for entry: FarmLogEntry) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [entry.id.uuidString])
    }

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
