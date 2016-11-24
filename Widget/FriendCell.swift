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
    @IBOutlet weak var watchButton: UIButton!
    @IBOutlet weak var onlineImageView: UIImageView!
    @IBOutlet weak var onlineImageViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var onlineImageViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var onlineImageViewLeftMarginConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.avatarImageView.layer.cornerRadius = 16.0
        self.avatarImageView.clipsToBounds = true
    }
    
    func prepareCell(user: VKUser) {
        
        self.avatarImageView.sd_setImage(with: user.photo_100.url, placeholderImage: nil)
        
        let fullName = NSMutableAttributedString()
        let firstName = NSAttributedString(string: user.first_name!,
                                       attributes: [NSFontAttributeName : UIFont.systemFont(ofSize: 14.0, weight: UIFontWeightRegular)])
        let lastName = NSAttributedString(string: " \(user.last_name!)",
                                      attributes: [NSFontAttributeName:UIFont.systemFont(ofSize: 14.0, weight: UIFontWeightMedium)])
        fullName.append(firstName)
        fullName.append(lastName)
        
        self.nameLabel.attributedText = fullName
        
        let image = UIImage(named: "watch_icon")?.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
        
        self.watchButton.setImage(image, for: .normal)
        self.watchButton.tintColor = mainColor
        
        if !user.online.boolValue && (user.online_mobile != nil && !user.online_mobile.boolValue) {
            self.onlineImageViewLeftMarginConstraint.constant = 0
            self.onlineImageViewWidthConstraint.constant = 0
        } else {
            self.onlineImageViewLeftMarginConstraint.constant = 8
            if (user.online_mobile != nil && !user.online_mobile.boolValue) {
                self.onlineImageViewWidthConstraint.constant = 8
                self.onlineImageViewHeightConstraint.constant = 16
            } else {
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
