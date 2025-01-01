//
//  NotificationManager.swift
//  StoryScapeApp
//
//  Created by Dev Asheesh Chopra on 02/01/25.
//

import Foundation
import UserNotifications

/// A sample manager for handling local or push notifications.
class NotificationManager {
    
    static let shared = NotificationManager()
    private init() {}
    
    /// Request permission for user notifications
    func requestPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                completion(granted && error == nil)
            }
        }
    }
    
    /// Schedule a local notification as an example
    func scheduleLocalNotification(title: String, body: String, inSeconds seconds: Double) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
}
