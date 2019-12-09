//
//  OldPostsTableViewCell.swift
//  OurCampus
//
//  Created by Rafael Goldstein on 12/27/18.
//  Copyright © 2018 Rafael Goldstein. All rights reserved.
//

import UIKit

class OldPostsTableViewCell: UITableViewCell {

    @IBOutlet weak var date: UILabel!
    @IBOutlet weak var class1: UILabel!
    @IBOutlet weak var rate: UILabel!
    @IBOutlet weak var diff: UILabel!
    @IBOutlet weak var grade: UILabel!
    @IBOutlet weak var comment: UITextView!
    @IBOutlet weak var prof: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        date.adjustsFontSizeToFitWidth = true
        class1.adjustsFontSizeToFitWidth = true
        rate.adjustsFontSizeToFitWidth = true
        diff.adjustsFontSizeToFitWidth = true
        comment.adjustsFontForContentSizeCategory = true
        prof.adjustsFontSizeToFitWidth = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
