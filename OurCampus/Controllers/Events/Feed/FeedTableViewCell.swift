//
//  FeedTableViewCell.swift
//  OurCampus
//
//  Created by Rafael Goldstein on 7/18/19.
//  Copyright © 2019 Rafael Goldstein. All rights reserved.
//

import UIKit

class FeedTableViewCell: UITableViewCell {
    @IBOutlet weak var proPic: UIImageView!
    
    @IBOutlet weak var user: UILabel!
    @IBOutlet weak var event: UILabel!
    @IBOutlet weak var content: UIView!
    @IBOutlet weak var cell: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
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
