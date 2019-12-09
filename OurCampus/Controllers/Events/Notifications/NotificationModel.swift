//
//  NotificationModel.swift
//  OurCampus
//
//  Created by Rafael Goldstein on 8/21/19.
//  Copyright © 2019 Rafael Goldstein. All rights reserved.
//

import Foundation
class NotificationModel {
    
    var inviter:String?
    var title:String?
    var time:String?
    var pic:Data?
    var viewed:Bool?
    var eventid:String?
    var inviteDisplay:String?
    var eventDisplay:String?
    
    init(inviter1:String, title1:String, time1:String, pic1:Data, viewed1:Bool, eventid1:String, inviteDisplay1:String,eventDisplay1:String)
    {
        self.inviter = inviter1
        self.title = title1
        self.time = time1
        self.pic = pic1
        self.viewed = viewed1
        self.eventid = eventid1
        self.inviteDisplay = inviteDisplay1
        self.eventDisplay = eventDisplay1
    }
    
}
