//
//  EditProfAccountInfoCell.swift
//  iONLive
//
//  Created by Gadgeon on 12/21/15.
//  Copyright © 2015 Gadgeon. All rights reserved.
//

import UIKit

class EditProfAccountInfoCell: UITableViewCell {
    
   static let identifier = "EditProfAccountInfoCell"

    @IBOutlet weak var borderLine: UILabel!
    @IBOutlet weak var accountInfoTitleLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        self.bringSubviewToFront(borderLine)
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }

}
