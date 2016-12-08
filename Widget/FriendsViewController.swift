//
//  TodayViewController.swift
//  Widget
//
//  Created by Aynur Galiev on 24.ноября.2016.
//  Copyright © 2016 Aynur Galiev. All rights reserved.
//

import UIKit
import NotificationCenter

final class FriendsViewController: UIViewController, NCWidgetProviding {
        
    @IBOutlet weak var tableView: UITableView!
    private var presenter: FriendsPresenter = FriendsPresenter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.registerCellNib(type: FriendCell.self)
        self.tableView.dataSource = self.presenter
        self.tableView.delegate = self.presenter
    }
    
    func widgetMarginInsets(forProposedMarginInsets defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
        return UIEdgeInsets.zero
    }
    
    @nonobjc func widgetPerformUpdate(completionHandler: ((NCUpdateResult) -> Void)) {
        NSLog("Fetched")
        completionHandler(NCUpdateResult.newData)
    }
}
