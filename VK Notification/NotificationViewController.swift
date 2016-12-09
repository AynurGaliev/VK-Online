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
import VKSdkFramework

class NotificationViewController: UIViewController, UNNotificationContentExtension, UITableViewDataSource {

    private var users: [String] = []
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let bounds = self.view.bounds
        self.preferredContentSize = CGSize(width: bounds.size.width, height: bounds.size.width*0.5)
    }
    
    func didReceive(_ notification: UNNotification) {
        self.users = notification.request.content.userInfo["users"] as? [String] ?? []
        self.tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.users.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        let userString = self.users[indexPath.row]
        cell?.textLabel?.text = "\(indexPath.row + 1). \(userString)"
        return cell!
    }
}
