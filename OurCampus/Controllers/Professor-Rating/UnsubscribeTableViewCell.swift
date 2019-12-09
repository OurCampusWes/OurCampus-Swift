//
//  UnsubscribeTableViewCell.swift
//  
//
//  Created by Rafael Goldstein on 10/29/19.
//

import UIKit

class UnsubscribeTableViewCell: UITableViewCell {

    @IBOutlet weak var className: UILabel!
    @IBOutlet weak var Cell: UIView!
    
    @IBOutlet weak var content: UIView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Make it card-like
        Cell.layer.shadowOpacity = 1
        Cell.layer.shadowRadius = 2
        Cell.layer.shadowOffset = CGSize(width: 3, height: 3)
        Cell.layer.masksToBounds = true
        Cell.layer.cornerRadius = 10
        content.backgroundColor = UIColor.lightGray
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
