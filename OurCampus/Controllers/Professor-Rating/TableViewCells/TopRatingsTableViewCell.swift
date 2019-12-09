//
//  TopRatingsTableViewCell.swift
//  OurCampusXcode
//
//  Created by Rafael Goldstein on 12/21/18.
//  Copyright © 2018 Rafael Goldstein. All rights reserved.
//

import UIKit

class TopRatingsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var prof: UILabel!
    @IBOutlet weak var rate: UILabel!
    @IBOutlet weak var number: UILabel!
    

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
