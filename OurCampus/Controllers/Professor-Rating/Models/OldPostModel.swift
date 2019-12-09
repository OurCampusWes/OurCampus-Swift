//
//  OldPostModel.swift
//  OurCampus
//
//  Created by Rafael Goldstein on 12/27/18.
//  Copyright © 2018 Rafael Goldstein. All rights reserved.
//

import Foundation

class OldPostModel {
    
    var rate: String?
    var difficulty: String?
    var comment: String?
    var className: String?
    var grade: String?
    var date: String?
    var prof1: String?
    
    init(rate1: String?, difficulty1: String?, com1: String?, className1: String?, grade1: String?, date1: String?, prof: String?)
    {
        self.rate = rate1
        self.difficulty = difficulty1
        self.comment = com1
        self.className = className1
        
        
        self.date = date1
        
        if grade1 == nil {
            self.grade = "Not Available"
        }
        else {
            self.grade = grade1
        }

        self.prof1 = prof
    }
}
