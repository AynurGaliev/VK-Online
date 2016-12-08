//
//  NotificationViewController.swift
//  VK Notification
//
//  Created by Aynur Galiev on 7.декабря.2016.
//  Copyright © 2016 Aynur Galiev. All rights reserved.
//

import UIKit
import UserNotifications
import UserNotificationsUI

class NotificationViewController: UIViewController, UNNotificationContentExtension {

    @IBOutlet var label: UILabel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("DID load")
    }
    
    func didReceive(_ notification: UNNotification) {
        print(notification)
        self.label?.text = notification.request.content.body
    }

    
    
}
