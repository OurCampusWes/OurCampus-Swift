//
//  ViewControllerProfTableViewCell.swift
//  OurCampusXcode
//
//  Created by Rafael Goldstein on 12/20/18.
//  Copyright © 2018 Rafael Goldstein. All rights reserved.
//

import UIKit

class BrowseProfsTableViewCell: UITableViewCell {

    @IBOutlet weak var cl: UILabel!
    @IBOutlet weak var rate: UILabel!
    @IBOutlet weak var difficulty: UILabel!
    @IBOutlet weak var comment: UITextView!
    @IBOutlet weak var grade: UILabel!
    @IBOutlet weak var textbook: UILabel!
    @IBOutlet weak var attendance: UILabel!
    @IBOutlet weak var takeAgain: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        //comment.lineBreakMode = .byWordWrapping
        cl.adjustsFontSizeToFitWidth = true
        rate.adjustsFontSizeToFitWidth = true
        difficulty.adjustsFontSizeToFitWidth = true
        attendance.adjustsFontSizeToFitWidth = true
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
        
    }

}
