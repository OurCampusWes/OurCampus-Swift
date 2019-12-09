//
//  AddFriendsTableViewCell.swift
//  OurCampus
//
//  Created by Rafael Goldstein on 7/15/19.
//  Copyright © 2019 Rafael Goldstein. All rights reserved.
//

import UIKit

class AddFriendsTableViewCell: UITableViewCell {
    @IBOutlet weak var name: UITextField!
    @IBOutlet weak var addButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
