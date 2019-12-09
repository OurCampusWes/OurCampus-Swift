//
//  RadioButton.swift
//  OurCampusXcode
//
//  Created by Rafael Goldstein on 12/24/18.
//  Copyright © 2018 Rafael Goldstein. All rights reserved.
//

import UIKit

class RadioButton: UIButton {
    
    var alternateButton:Array<RadioButton>?
    
    override func awakeFromNib() {
        self.layer.cornerRadius = 5
        self.layer.borderWidth = 2.0
        self.layer.masksToBounds = true
    }
    
    func unselectAlternateButtons(){
        if alternateButton != nil {
            self.isSelected = true
            
            for aButton:RadioButton in alternateButton! {
                aButton.isSelected = false
            }
        }else{
            toggleButton()
        }
    }
    
    func setText(text: String) {
        self.setTitle(text, for: .normal)
        self.setTitleColor(UIColor.black, for: .normal)
        self.titleLabel?.font = UIFont(name: "Georgia", size: 14)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        unselectAlternateButtons()
        super.touchesBegan(touches, with: event)
    }
    
    func toggleButton(){
        self.isSelected = !isSelected
    }
    
    override var isSelected: Bool {
        didSet {
            if isSelected {
                self.layer.borderColor = UIColor(red:0.77, green:0.12, blue:0.23, alpha:1.0).cgColor
                self.layer.backgroundColor = UIColor(red:0.77, green:0.12, blue:0.23, alpha:1.0).cgColor
            } else {
                self.layer.borderColor = UIColor(red:0.84, green:0.84, blue:0.84, alpha:1.0).cgColor
                self.layer.backgroundColor = UIColor(red:0.84, green:0.84, blue:0.84, alpha:1.0).cgColor
            }
        }
    }
}
