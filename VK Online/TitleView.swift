//
//  TitleView.swift
//  VK Online
//
//  Created by Aynur Galiev on 29.ноября.2016.
//  Copyright © 2016 Aynur Galiev. All rights reserved.
//

import UIKit

class TitleView: UIView {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.titleLabel.frame = CGRect.init(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height*0.6)
        self.subtitleLabel.frame = CGRect.init(x: 0, y: self.frame.size.height*0.6, width: self.frame.size.width, height: self.frame.size.height*0.4)
    }

}
