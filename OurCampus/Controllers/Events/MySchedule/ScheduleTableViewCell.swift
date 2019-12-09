//
//  ScheduleTableViewCell.swift
//  OurCampus
//
//  Created by Rafael Goldstein on 7/15/19.
//  Copyright © 2019 Rafael Goldstein. All rights reserved.
//

import UIKit

class ScheduleTableViewCell: UITableViewCell {

    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var cell: UIView!
    @IBOutlet weak var day: UILabel!
    @IBOutlet weak var month: UILabel!
    @IBOutlet weak var content: UIView!
    @IBOutlet weak var author: UILabel!
    @IBOutlet weak var pub: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        // Make it card-like
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
