//
//  HeaderView.swift
//  VK Online
//
//  Created by Aynur Galiev on 24.11.16.
//  Copyright © 2016 Aynur Galiev. All rights reserved.
//

import UIKit

final class HeaderView: UITableViewHeaderFooterView {

    @IBOutlet weak var label: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundView = UIView.init()
    }
}
