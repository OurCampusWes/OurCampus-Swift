//
//  SettingsTableViewCell.swift
//  OurCampus
//
//  Created by Rafael Goldstein on 9/19/19.
//  Copyright © 2019 Rafael Goldstein. All rights reserved.
//

import UIKit

class SettingsTableViewCell: UITableViewCell {
   
    @IBOutlet var button1: UIButton!
    @IBOutlet var cell: UIView!
    @IBOutlet var content: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        cell.layer.shadowOpacity = 1
        cell.layer.shadowRadius = 2
        cell.layer.shadowOffset = CGSize(width: 1, height: 1)
        cell.layer.masksToBounds = true
        cell.layer.cornerRadius = 10
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
