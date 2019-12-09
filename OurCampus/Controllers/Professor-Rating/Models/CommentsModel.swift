//
//  File.swift
//  OurCampusXcode
//
//  Created by Rafael Goldstein on 12/20/18.
//  Copyright © 2018 Rafael Goldstein. All rights reserved.
//

import Foundation

class CommentsModel {
    
    var rate: String?
    var difficulty: String?
    var comment: String?
    var className: String?
    var accessible: String?
    var feedback: String?
    var recommend: String?
    var lecture: String?
    var returns: String?
    var discussion: String?
    var grade: String?
    var user: String?
    var date: String?
    
    init(rate1: String?, difficulty1: String?, com1: String?, className1: String?, acc: String?, feed: String?, rec: String?, lect: String?, ret: String?, disc: String?, grade1: String?, user1: String?, d: String?)
    {
        self.rate = rate1
        self.difficulty = difficulty1
        self.comment = com1
        self.className = className1
       
        self.accessible = acc
        
        self.feedback = feed
       
        self.recommend = rec
        
        self.lecture = lect
    
        self.returns = ret
        
        self.discussion = disc
        
        if grade1 == nil {
            self.grade = "Not Available"
        }
        else {
            self.grade = grade1
        }
        
        self.user = user1
        self.date = d
    }
    
}
