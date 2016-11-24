//
//  FriendsPresenter.swift
//  VK Online
//
//  Created by Aynur Galiev on 24.ноября.2016.
//  Copyright © 2016 Aynur Galiev. All rights reserved.
//

import UIKit
import NotificationCenter

final class FriendsPresenter: NSObject, NCWidgetProviding {

    @nonobjc func widgetPerformUpdate(completionHandler: ((NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        
        completionHandler(NCUpdateResult.newData)
    }
    
    func widgetMarginInsets(forProposedMarginInsets defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
        return UIEdgeInsets.zero
    }
    
}

extension FriendsPresenter: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FriendsCell") as! FriendCell
        cell.nameLabel.text = "\(indexPath.row)"
        return cell
    }
}

extension FriendsPresenter: UITableViewDelegate {
    
}
