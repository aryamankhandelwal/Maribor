//
//  MariborApp.swift
//  Maribor
//
//  Created by Aryaman on 7/30/25.
//

import SwiftUI
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Defer notification setup to avoid blocking launch
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Set up notification delegate
            UNUserNotificationCenter.current().delegate = self
        }
        
        return true
    }
    
    // Handle notifications when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
    
    // Handle notification taps
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}

@main
struct MariborApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .onAppear {
                    // Defer any heavy initialization
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        // Any additional setup can go here
                    }
                }
        }
    }
}
