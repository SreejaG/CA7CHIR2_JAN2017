//
//  MySharedChannelsCell.swift
//  iONLive
//
//  Created by Gadgeon on 12/22/15.
//  Copyright © 2015 Gadgeon. All rights reserved.
//

import UIKit

class MySharedChannelsCell: UITableViewCell {
    
    
    let channelIdKey = "channelId"
    let channelSelectionkey = "channelSelection"
    static let identifier = "MySharedChannelsCell"
    
    @IBOutlet weak var avatarIconImageView: UIImageView!
    @IBOutlet weak var channelNameLabel: UILabel!
    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var sharedCountLabel: UILabel!
    @IBOutlet weak var channelSelectionButton: UIButton!
    
    var cellDataSource:[String:AnyObject]?
    
    var selectedArray: NSMutableArray = NSMutableArray()
    var deselectedArray: NSMutableArray = NSMutableArray()
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    @IBAction func channelSelectionClicked(sender: AnyObject)
    {
        
        if cellDataSource != nil{
            let selectedValue: String = cellDataSource![channelIdKey] as! String
            if(selectedArray.containsObject(selectedValue)){
                selectedArray.removeObject(selectedValue)
                deselectedArray.addObject(selectedValue)
                cellDataSource![channelSelectionkey] = "0"
                channelSelectionButton.setImage(UIImage(named:"red-circle"), forState: .Normal)
                sharedCountLabel.hidden = true
                avatarIconImageView.hidden = true
            }
            else{
                cellDataSource![channelSelectionkey] = "1"
                selectedArray.addObject(selectedValue)
                deselectedArray.removeObject(selectedValue)
                channelSelectionButton.setImage(UIImage(named:"CheckOn"), forState: .Normal)
                sharedCountLabel.hidden = false
                avatarIconImageView.hidden = false
            }
            
        }
    }
}
