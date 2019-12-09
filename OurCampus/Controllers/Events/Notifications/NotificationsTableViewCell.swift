//
//  NotificationsTableViewCell.swift
//  OurCampus
//
//  Created by Rafael Goldstein on 8/21/19.
//  Copyright © 2019 Rafael Goldstein. All rights reserved.
//

import UIKit

class NotificationsTableViewCell: UITableViewCell {

    @IBOutlet weak var picture: UIImageView!
    @IBOutlet weak var invitedBy: UILabel!
    @IBOutlet weak var event: UILabel!
    @IBOutlet weak var cell: UIView!
    @IBOutlet weak var content: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        cell.layer.shadowOpacity = 1
        cell.layer.shadowRadius = 2
        cell.layer.shadowOffset = CGSize(width: 3, height: 3)
        cell.layer.masksToBounds = true
        cell.layer.cornerRadius = 10
        content.backgroundColor = UIColor.lightGray
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
