//
//  MyChannelNotificationCell.swift
//  iONLive
//
//  Created by Gadgeon Smart Systems  on 3/11/16.
//  Copyright © 2016 Gadgeon. All rights reserved.
//

import UIKit

class MyChannelNotificationCell: UITableViewCell {
    
    static let identifier = "MyChannelNotificationCell"
    
    @IBOutlet var NotificationSenderImageView: UIImageView!
    @IBOutlet var notificationText: UILabel!
    @IBOutlet var NotificationImage: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        NotificationSenderImageView.layer.cornerRadius = NotificationSenderImageView.frame.size.width/2
        NotificationSenderImageView.layer.masksToBounds = true
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
