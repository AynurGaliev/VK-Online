//
//  FriendCell.swift
//  VK Online
//
//  Created by Aynur Galiev on 24.ноября.2016.
//  Copyright © 2016 Aynur Galiev. All rights reserved.
//

import UIKit
import VKSdkFramework
import WebImage

final class FriendCell: UITableViewCell {

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var onlineImageView: UIImageView!
    @IBOutlet weak var onlineImageViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var onlineImageViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var watchButton: UIButton!
    private var user: User!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.avatarImageView.layer.cornerRadius = 16.0
        self.avatarImageView.clipsToBounds = true
        self.avatarImageView.tintColor = mainColor
    }
    
    @IBAction func watchAction(_ sender: UIButton) {
        var users: [User] = Storage.shared.get()
        if let index = users.index(where: { (user) -> Bool in
            return user.user.id == self.user.user.id
        }) {
            users[index].isWatching = !self.user.isWatching
            var watchingIDs: [String] = Storage.shared.get()
            if users[index].isWatching {
                watchingIDs.append(users[index].user.id.stringValue)
            } else {
                if let index = watchingIDs.index(where: { (str) -> Bool in
                    return str == users[index].user.id.stringValue
                }) {
                    watchingIDs.remove(at: index)
                }
            }
            Storage.shared.set(ids: watchingIDs)
        }
        Storage.shared.set(object: users)
        self.user.isWatching = !self.user.isWatching
        self.updateButtonState()
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: NSNotification.Name.init("WatchingFriendsDidChanged"), object: nil)
        }
    }
    
    func updateButtonState() {
        if self.user.isWatching {
            self.watchButton.setTitle("Unwatch", for: .normal)
            self.watchButton.setTitleColor(UIColor.red, for: .normal)
        } else {
            self.watchButton.setTitle("Watch", for: .normal)
            self.watchButton.setTitleColor(mainColor, for: .normal)
        }
    }
    
    func prepareCell(user: User) {
        
        self.user = user
        
        self.updateButtonState()
        self.avatarImageView.sd_setImage(with: user.user.photo_100.url,
                                         placeholderImage: UIImage(named: "placeholder"))
        
        let fullName = NSMutableAttributedString()
        let firstName = NSAttributedString(string: user.user.first_name!,
                                       attributes: [NSFontAttributeName : UIFont.systemFont(ofSize: 14.0, weight: UIFontWeightRegular)])
        let lastName = NSAttributedString(string: " \(user.user.last_name!)",
                                      attributes: [NSFontAttributeName:UIFont.systemFont(ofSize: 14.0, weight: UIFontWeightMedium)])
        fullName.append(firstName)
        fullName.append(lastName)
        
        self.nameLabel.attributedText = fullName
        
        let isOnline = (user.user.online != nil        && user.user.online.boolValue) &&
                       (user.user.online_mobile != nil && user.user.online_mobile.boolValue)
        
        if !isOnline {
            self.onlineImageViewWidthConstraint.constant = 0
        } else {
            if (user.user.online_mobile != nil && user.user.online_mobile.boolValue) {
                self.onlineImageView.image = UIImage(named: "online_mobile_icon")
                self.onlineImageViewWidthConstraint.constant = 8
                self.onlineImageViewHeightConstraint.constant = 16
            } else {
                self.onlineImageView.image = UIImage(named: "online_icon")
                self.onlineImageViewWidthConstraint.constant = 6
                self.onlineImageViewHeightConstraint.constant = 6
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.nameLabel.text = nil
        self.avatarImageView.sd_cancelCurrentImageLoad()
    }
}
