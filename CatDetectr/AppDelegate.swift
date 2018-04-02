//
//  AppDelegate.swift
//  CatDetectr
//
//  Created by Sophos on 2018-03-23.
//  Copyright © 2018 Sophos. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSUserNotificationCenterDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        NSUserNotificationCenter.default.delegate = self

    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        NSUserNotificationCenter.default.removeAllDeliveredNotifications()
    }
    func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
        return true
    }
}

