//
//  BrowseReviewTableViewCell.swift
//  OurCampus
//
//  Created by Rafael Goldstein on 2/1/19.
//  Copyright © 2019 Rafael Goldstein. All rights reserved.
//

import UIKit

class BrowseReviewTableViewCell: UITableViewCell {

    @IBOutlet weak var cl: UILabel!
    @IBOutlet weak var difficulty: UILabel!
    @IBOutlet weak var comment: UITextView!
    @IBOutlet weak var grade: UILabel!
    @IBOutlet weak var rate: UILabel!
    @IBOutlet weak var recommend: UILabel!
    @IBOutlet weak var lecture: UILabel!
    @IBOutlet weak var accessible: UILabel!
    @IBOutlet weak var assignment: UILabel!
    @IBOutlet weak var feedback: UILabel!
    @IBOutlet weak var discussion: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        //comment.lineBreakMode = .byWordWrapping
        cl.adjustsFontSizeToFitWidth = true
        rate.adjustsFontSizeToFitWidth = true
        difficulty.adjustsFontSizeToFitWidth = true
        lecture.adjustsFontSizeToFitWidth = true
        accessible.adjustsFontSizeToFitWidth = true
        assignment.adjustsFontSizeToFitWidth = true
        discussion.adjustsFontSizeToFitWidth = true
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
        
    }

}
