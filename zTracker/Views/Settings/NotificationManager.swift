//
//  NotificationManager.swift
//  zTracker
//
//  Created by Jia Sahar on 12/28/25.
//

import UserNotifications
import SwiftData

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    /// Handles a notification delivered while the app is in the foreground.
    /// Invokes the completion handler to present a banner and play a sound.
    /// - Parameters:
    ///   - willPresent: The notification being delivered.
    ///   - completionHandler: Called with presentation options to control how the notification is presented; this implementation requests `.banner` and `.sound`.
    func userNotificationCenter(
        _ _: UNUserNotificationCenter,
        willPresent: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound])
    }
}

func scheduleNotification(for habit: Habit) async {
    guard let reminderTime = habit.reminder else { return }
    
    // Cancel existing first
    UNUserNotificationCenter.current()
        .removePendingNotificationRequests(withIdentifiers: [habit.id.uuidString])
    
    let content = UNMutableNotificationContent()
    content.title = "Habit Reminder"
    content.body = habit.title
    content.sound = .default
    
    // Extract hour/minute from reminder date
    let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
    
    // Create daily repeating trigger
    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
    
    let request = UNNotificationRequest(
        identifier: habit.id.uuidString,
        content: content,
        trigger: trigger
    )
    
    try? await UNUserNotificationCenter.current().add(request)
}