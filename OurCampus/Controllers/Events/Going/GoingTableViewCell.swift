//
//  TableViewCell.swift
//  OurCampus
//
//  Created by Rafael Goldstein on 8/23/19.
//  Copyright © 2019 Rafael Goldstein. All rights reserved.
//

import UIKit

class GoingTableViewCell: UITableViewCell {
    @IBOutlet weak var name: UITextField!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
