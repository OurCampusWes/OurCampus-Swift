//
//  TableViewCell.swift
//  OurCampus
//
//  Created by Rafael Goldstein on 7/10/19.
//  Copyright © 2019 Rafael Goldstein. All rights reserved.
//

import UIKit

class AllEventsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var time: UITextField!
    @IBOutlet weak var title: UITextField!
    @IBOutlet weak var author: UITextField!
    @IBOutlet weak var cell: UIView!
    @IBOutlet weak var going: UILabel!
    
    @IBOutlet weak var content: UIView!
    @IBOutlet weak var day: UILabel!
    @IBOutlet weak var month: UILabel!
    @IBOutlet weak var pub: UILabel!
    @IBOutlet weak var cat: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
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
