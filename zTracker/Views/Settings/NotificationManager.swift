//
//  NotificationManager.swift
//  zTracker
//
//  Created by Jia Sahar on 12/28/25.
//

import Foundation
import UserNotifications
import AppIntents
import SwiftData

#if canImport(UIKit)
import UIKit
#endif

// TODO: - Integration checklist

// Duration “Open to Log” action:
// - Implement a URL/deep link to open EntryEditorView for the habit today (or App Intent to log)
// - Read "deepLink" from the notification’s userInfo for a URL scheme.

// MARK: - NotificationsActionHandler

protocol NotificationsActionHandler: AnyObject, Sendable {
    func isHabitLoggedToday(habitID: UUID) async -> Bool

    func handleLogBoolean(habitID: UUID, value: Bool) async

    func handleLogNumeric(habitID: UUID, value: Double) async

    func handleLogRating(habitID: UUID, value: Int) async

    func remainingHabitsCountToday() async -> Int
}

final class DefaultNotificationsActionHandler: NotificationsActionHandler {
    
    func isHabitLoggedToday(habitID: UUID) async -> Bool {
        do {
            let context = ModelContext(try getModelContainer())
            let descriptor = FetchDescriptor<HabitEntry>(predicate: #Predicate<HabitEntry> { entry in
                entry.habit?.id == habitID && entry.date == today
            })
            return try context.fetch(descriptor).first != nil
        } catch { return false }
    }
    
    func handleLogBoolean(habitID: UUID, value: Bool) async {
        let intent = LogBooleanHabitIntent()
        intent.habit = HabitEntity(id: habitID, title: "", type: .boolean(goal: nil))
        intent.completion = value
        intent.date = today
        do {
            _ = try await intent.perform()
            await NotificationsManager.shared.cancelHabitFollowupReminders(habitID: habitID)
        } catch { }
    }
    
    func handleLogNumeric(habitID: UUID, value: Double) async {
        let intent = LogNumericHabitIntent()
        intent.habit = HabitEntity(id: habitID, title: "", type: .numeric(min: 0, max: 0, unit: "", goal: nil))
        intent.value = value
        intent.date = today
        do {
            _ = try intent.perform()
            await NotificationsManager.shared.cancelHabitFollowupReminders(habitID: habitID)
        } catch { }
    }
    
    func handleLogRating(habitID: UUID, value: Int) async {
        let intent = LogRatingHabitIntent()
        intent.habit = HabitEntity(id: habitID, title: "", type: .rating(min: 0, max: 5, goal: nil))
        intent.value = value
        intent.date = today
        do {
            _ = try intent.perform()
            await NotificationsManager.shared.cancelHabitFollowupReminders(habitID: habitID)
        } catch { }
    }
    
    func remainingHabitsCountToday() -> Int {
        do {
            let context = ModelContext(try getModelContainer())
            let total = try context.fetchCount(FetchDescriptor<Habit>(predicate: #Predicate { !$0.isArchived }))

            let completed = try context.fetchCount(FetchDescriptor<HabitEntry>(predicate: #Predicate {
                        $0.date == today && $0.habit?.isArchived == false
                    })
            )
            return (total - completed)
        } catch { return 0 }
    }

}

// MARK: - NotificationsManager

@MainActor
final class NotificationsManager {

    // Singleton
    static let shared = NotificationsManager()
    private init() {}

    // Bridge for data mutations and queries
    weak var actionHandler: NotificationsActionHandler?

    // MARK: - Authorization

    @discardableResult
    func requestAuthorization(allowProvisional: Bool) async -> UNAuthorizationStatus {
        let center = UNUserNotificationCenter.current()
        var options: UNAuthorizationOptions = [.alert, .sound, .badge]
        if allowProvisional { options.insert(.provisional) }

        do {
            let granted = try await center.requestAuthorization(options: options)
            if granted { await registerCategories() }
        } catch { }

        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    func openAppSettings() {
        #if canImport(UIKit)
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
        #endif
    }

    // MARK: - Category & Actions

    func registerCategories() async {
        let booleanCategory = UNNotificationCategory(
            identifier: "habit.boolean",
            actions: [
                UNNotificationAction(
                    identifier: "action.boolean.complete",
                    title: "Mark Complete",
                    options: []
                ),

                UNNotificationAction(
                    identifier: "action.boolean.incomplete",
                    title: "Mark Incomplete",
                    options: []
                )
            ],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        let ratingCategory = UNNotificationCategory(
            identifier: "habit.rating",
            actions: [
                UNTextInputNotificationAction(identifier: "action.rating.enter",
                                              title: NSLocalizedString("Enter Rating", comment: "Rating input"),
                                              options: [],
                                              textInputButtonTitle: NSLocalizedString("Save", comment: "Save input"),
                                              textInputPlaceholder: NSLocalizedString("e.g. 4", comment: "Rating placeholder"))
            ],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        let numericCategory = UNNotificationCategory(
            identifier: "habit.numeric",
            actions: [
                UNTextInputNotificationAction(identifier: "action.numeric.enter",
                                              title: NSLocalizedString("Enter Value", comment: "Numeric input"),
                                              options: [],
                                              textInputButtonTitle: NSLocalizedString("Save", comment: "Save input"),
                                              textInputPlaceholder: NSLocalizedString("e.g. 2.5", comment: "Numeric placeholder"))
            ],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        let durationCategory = UNNotificationCategory(
            identifier: "habit.duration",
            actions: [
                UNNotificationAction(identifier: "action.duration.open",
                                     title: NSLocalizedString("Open to Log", comment: "Open app to log duration"),
                                     options: [.foreground])
            ],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        let summaryCategory = UNNotificationCategory(
            identifier: "habit.dailySummary",
            actions: [
                UNNotificationAction(identifier: "action.open",
                                     title: NSLocalizedString("Review", comment: "Open to review remaining"),
                                     options: [.foreground])
            ],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories(
            [booleanCategory, ratingCategory, numericCategory, durationCategory, summaryCategory]
        )
    }

    // MARK: - Public API (Settings toggle helpers)

    static func remindersTurnedOn() {
        Task { @MainActor in
            let status = await NotificationsManager.shared.requestAuthorization(allowProvisional: false)
            if status == .authorized || status == .provisional {
                await NotificationsManager.shared.registerCategories()
            }
        }
    }

    static func remindersTurnedOff() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }

    // MARK: - Scheduling (Habits)

    func scheduleHabitReminder(habit: Habit) async {
        let habitID: UUID = habit.id
        let title: String = habit.title
        let type: HabitType = habit.type
        let reminderTime: Date? = habit.reminder
        
        await cancelHabitReminders(habitID: habitID)

        guard let reminderTime else { return }

        let dateComponents = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        let content = makeHabitNotificationContent(habitID: habitID, title: title, type: type, isFollowUp: false)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let requestID = makeRequestIdentifier(habitID: habitID, isFollowUp: false)
        let request = UNNotificationRequest(identifier: requestID, content: content, trigger: trigger)

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch { }

        // schedule a one-off follow-up for the next occurrence + 30 minutes.
        await scheduleNextOccurrenceFollowUp(habitID: habitID, title: title, type: type, timeOfDay: reminderTime)
    }

    func cancelHabitReminders(habitID: UUID) async {
        let center = UNUserNotificationCenter.current()
        let basePrefix = "habit.\(habitID.uuidString)"
        await center.removePendingNotificationRequests(withIdentifiersMatchingPrefix: basePrefix)
        center.removeDeliveredNotifications(withIdentifiers: [basePrefix])
    }

    func cancelHabitFollowupReminders(habitID: UUID) async {
        let center = UNUserNotificationCenter.current()
        let followPrefix = "habit.\(habitID.uuidString).followup"
        await center.removePendingNotificationRequests(withIdentifiersMatchingPrefix: followPrefix)
    }

    /// Schedules a 30-minute follow-up notification if the habit is not yet logged (triggered relative to now).
    func scheduleFollowUpIfNeeded(habitID: UUID, title: String, type: HabitType, originalRequestID: String) async {
        guard let handler = self.actionHandler else { return }
        let isLogged = await handler.isHabitLoggedToday(habitID: habitID)
        guard !isLogged else { return }

        let content = makeHabitNotificationContent(habitID: habitID,
                                                   title: title,
                                                   type: type,
                                                   isFollowUp: true)

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 30 * 60, repeats: false)
        let followUpID = makeFollowUpRequestIdentifier(habitID: habitID, originalRequestID: originalRequestID)

        let request = UNNotificationRequest(identifier: followUpID, content: content, trigger: trigger)
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch { }
    }

    /// Computes next occurrence of the given time-of-day and schedules a one-off follow-up at +30m.
    private func scheduleNextOccurrenceFollowUp(habitID: UUID,
                                                title: String,
                                                type: HabitType,
                                                timeOfDay: Date) async {
        // Cancel previously planned follow-ups for this habit
        await cancelHabitFollowupReminders(habitID: habitID)

        let now = Date()
        let cal = Calendar.current
        var comps = cal.dateComponents([.hour, .minute], from: timeOfDay)
        let todayComps = cal.dateComponents([.year, .month, .day], from: now)
        comps.year = todayComps.year
        comps.month = todayComps.month
        comps.day = todayComps.day

        var next = cal.date(from: comps) ?? now
        if next <= now {
            next = cal.date(byAdding: .day, value: 1, to: next) ?? now
        }
        guard let followDate = cal.date(byAdding: .minute, value: 30, to: next) else { return }

        let content = makeHabitNotificationContent(habitID: habitID, title: title, type: type, isFollowUp: true)
        let interval = max(1, followDate.timeIntervalSinceNow)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let id = "habit.\(habitID.uuidString).followup.\(UUID().uuidString)"
        let req = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        
        do {
            try await UNUserNotificationCenter.current().add(req)
        } catch { }
    }

    // MARK: - Scheduling (Daily Summary)

    /// Schedules or updates the daily summary notification at a specific time of day.
    func scheduleDailySummary(at time: Date) async {
        await cancelDailySummary()

        let comps = Calendar.current.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)

        let content = UNMutableNotificationContent()
        content.categoryIdentifier = "habit.dailySummary"
        content.threadIdentifier = "summary.daily"
//        content.summaryArgument = NSLocalizedString("Habits", comment: "Summary argument")
//        content.summaryArgumentCount = 1

        if let count = try? await remainingCount() {
            content.title = NSLocalizedString("Daily Summary", comment: "Daily summary title")
            // Consider adding a .stringsdict for proper pluralization
            content.body = String(format: NSLocalizedString("You have %d habits remaining today.", comment: "Daily summary body"), count)
        } else {
            content.title = NSLocalizedString("Daily Summary", comment: "Daily summary title")
            content.body = NSLocalizedString("Check your habits for today.", comment: "Fallback summary body")
        }

        let request = UNNotificationRequest(identifier: "summary.daily", content: content, trigger: trigger)
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            // Handle scheduling error if necessary.
        }
    }

    /// Cancels the scheduled daily summary notification.
    func cancelDailySummary() async {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["summary.daily"])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ["summary.daily"])
    }

    // MARK: - Content Builders

    private func makeHabitNotificationContent(habitID: UUID, title: String, type: HabitType, isFollowUp: Bool) -> UNMutableNotificationContent {
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = makeBody(for: type, isFollowUp: isFollowUp)
        content.sound = .default

        if isFollowUp {
            content.interruptionLevel = .timeSensitive
        }

        content.categoryIdentifier = categoryIdentifier(for: type)

        // Optional deep link you can handle in your app to open EntryEditorView for duration
        // e.g., ztracker://entry?habitID=...&date=YYYY-MM-DD
        if case .duration = type {
            let todayString = ISO8601DateFormatter().string(from: Calendar.current.startOfDay(for: Date()))
            let deepLink = "ztracker://entry?habitID=\(habitID.uuidString)&date=\(todayString)"
            content.userInfo["deepLink"] = deepLink
        }

        content.userInfo["habitID"] = habitID.uuidString
        content.userInfo["habitType"] = habitTypeKind(for: type)
        content.userInfo["isFollowUp"] = isFollowUp

//        content.summaryArgument = NSLocalizedString("Habits", comment: "Summary argument")
//        content.summaryArgumentCount = 1

        return content
    }

    private func makeBody(for type: HabitType, isFollowUp: Bool) -> String {
        switch type {
        case .boolean:
            return isFollowUp
            ? NSLocalizedString("Still not logged. Mark it complete?", comment: "Follow-up boolean")
            : NSLocalizedString("Time to check this off.", comment: "Initial boolean")
        case .duration:
            return isFollowUp
            ? NSLocalizedString("Still not logged. Open to log your time.", comment: "Follow-up duration")
            : NSLocalizedString("Open to log your time.", comment: "Initial duration")
        case .rating:
            return isFollowUp
            ? NSLocalizedString("Still not logged. Enter a rating.", comment: "Follow-up rating")
            : NSLocalizedString("Enter a quick rating.", comment: "Initial rating")
        case .numeric:
            return isFollowUp
            ? NSLocalizedString("Still not logged. Enter a value.", comment: "Follow-up numeric")
            : NSLocalizedString("Enter a quick value.", comment: "Initial numeric")
        }
    }

    private func categoryIdentifier(for type: HabitType) -> String {
        switch type {
        case .boolean: return "habit.boolean"
        case .duration: return "habit.duration"
        case .rating: return "habit.rating"
        case .numeric: return "habit.numeric"
        }
    }

    private func habitTypeKind(for type: HabitType) -> String {
        switch type {
        case .boolean: return "boolean"
        case .duration: return "duration"
        case .rating: return "rating"
        case .numeric: return "numeric"
        }
    }

    // MARK: - Identifiers

    private func makeRequestIdentifier(habitID: UUID, isFollowUp: Bool) -> String {
        let base = "habit.\(habitID.uuidString)"
        return isFollowUp ? "\(base).followup" : base
    }

    private func makeFollowUpRequestIdentifier(habitID: UUID, originalRequestID: String) -> String {
        "habit.\(habitID.uuidString).followup.\(originalRequestID).\(UUID().uuidString)"
    }

    // MARK: - Helpers

    private func remainingCount() async throws -> Int {
        if let handler = self.actionHandler {
            return await handler.remainingHabitsCountToday()
        }
        return 0
    }
}

// MARK: - UNUserNotificationCenter convenience

private extension UNUserNotificationCenter {
    func removePendingNotificationRequests(withIdentifiersMatchingPrefix prefix: String) async {
        let requests = await self.pendingNotificationRequests()
        let ids = requests.map(\.identifier).filter { $0.hasPrefix(prefix) }
        self.removePendingNotificationRequests(withIdentifiers: ids)
    }
}

// MARK: - NotificationDelegate

/// Handles presentation and user actions for notifications.
/// For action handling that requires model mutations, this class delegates to `NotificationsManager.shared.actionHandler`.
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        return [.banner, .sound, .list]
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) async {
        let userInfo = response.notification.request.content.userInfo
        let habitIDString = userInfo["habitID"] as? String
        let habitTypeString = userInfo["habitType"] as? String
        let isFollowUp = (userInfo["isFollowUp"] as? Bool) ?? false

        guard let habitIDString, let habitID = UUID(uuidString: habitIDString) else { return }
        let type = parseHabitType(from: habitTypeString)

        switch response.actionIdentifier {
        case "action.boolean.complete":
            await NotificationsManager.shared.actionHandler?.handleLogBoolean(habitID: habitID, value: true)
            
        case "action.boolean.incomplete":
            await NotificationsManager.shared.actionHandler?.handleLogBoolean(habitID: habitID, value: false)

        case "action.rating.enter":
            if let textResp = response as? UNTextInputNotificationResponse,
               let value = Int(textResp.userText) {
                await NotificationsManager.shared.actionHandler?.handleLogRating(habitID: habitID, value: value)
            }

        case "action.numeric.enter":
            if let textResp = response as? UNTextInputNotificationResponse,
               let value = Double(textResp.userText) {
                await NotificationsManager.shared.actionHandler?.handleLogNumeric(habitID: habitID, value: value)
            }

        case "action.duration.open":
            // Foreground open — route using your app’s scene delegate / URL handling as desired.
            // If you implement a URL scheme, you can read "deepLink" and open EntryEditorView.
            break

        default:
            break
        }

        // If this was the initial reminder (not a follow-up), set up a conditional follow-up in 30 minutes.
        if !isFollowUp {
            await NotificationsManager.shared.scheduleFollowUpIfNeeded(habitID: habitID,
                                                                       title: response.notification.request.content.title,
                                                                       type: type,
                                                                       originalRequestID: response.notification.request.identifier)
        }
    }

    private func parseHabitType(from string: String?) -> HabitType {
        switch string {
        case "boolean": return .boolean(goal: nil)
        case "duration": return .duration(goal: nil)
        case "rating": return .rating(min: 0, max: 5, goal: nil)
        case "numeric": return .numeric(min: 0, max: 0, unit: "", goal: nil)
        default: return .boolean(goal: nil)
        }
    }
}

