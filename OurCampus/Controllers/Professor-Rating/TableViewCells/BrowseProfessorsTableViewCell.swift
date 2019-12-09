//
//  BrowseProfessorsTableViewCell.swift
//  OurCampus
//
//  Created by Rafael Goldstein on 1/2/19.
//  Copyright © 2019 Rafael Goldstein. All rights reserved.
//

import UIKit

class BrowseProfessorsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var cl: UILabel!
    @IBOutlet weak var difficulty: UILabel!
    @IBOutlet weak var comment: UITextView!
    @IBOutlet weak var rate: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        //comment.lineBreakMode = .byWordWrapping
        cl.adjustsFontSizeToFitWidth = true
        rate.adjustsFontSizeToFitWidth = true
        difficulty.adjustsFontSizeToFitWidth = true
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
        
    }
    
}
