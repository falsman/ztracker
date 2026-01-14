//
//  NotificationManager.swift
//  zTracker
//
//  Created by Jia Sahar on 12/28/25.
//

import UserNotifications
import SwiftData

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
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
