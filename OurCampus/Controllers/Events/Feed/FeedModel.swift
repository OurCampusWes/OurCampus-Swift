//
//  FeedModel.swift
//  OurCampus
//
//  Created by Rafael Goldstein on 7/18/19.
//  Copyright © 2019 Rafael Goldstein. All rights reserved.
//

import Foundation
class FeedModel {
    
    var user:String?
    var event:String?
    var date:String?
    var pic:Data?
    var display:String?
    var eventid:String?
    var created:Bool
    
    init(user1:String, display1:String, event1:String, pic1:Data, date1:String, eventid1:String, created1:Bool)
    {
        self.user = user1
        self.event = event1
        self.pic = pic1
        self.date = date1
        self.display = display1
        self.eventid = eventid1
        self.created = created1
    }
    
}
