//
//  AcknowledgementsTableViewCell.swift
//  OurCampus
//
//  Created by Rafael Goldstein on 12/27/18.
//  Copyright © 2018 Rafael Goldstein. All rights reserved.
//

import UIKit

class AcknowledgementsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var ack: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        ack.textColor = UIColor.black
        ack.adjustsFontSizeToFitWidth = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
