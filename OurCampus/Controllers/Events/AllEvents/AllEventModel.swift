//
//  AllEventModel.swift
//  OurCampus
//
//  Created by Rafael Goldstein on 7/10/19.
//  Copyright © 2019 Rafael Goldstein. All rights reserved.
//

import Foundation

class AllEventModel {
    
    var timeCreated:String?
    var time:String?
    var title:String?
    var author:String?
    var going:[String: String]?
    var notgoing:[String: String]?
    var invited:[String: String]?
    var descript:String?
    var loc:String?
    var pic:Data?
    var pub:Bool?
    var key: String?
    var cat: String?
    var inviterDisplay:String?
    var eventid:String?
    var lin:String?
    
    init(pub1:Bool, pic1:Data, loc1:String, descript1:String, timeCreated1:String, time1:String, title1:String, author1:String, going1:[String: String], viewed1:[String: String], invited1:[String: String], key1:String, cat1:String, inviterDisplay1:String, eventid1:String, link1:String)
    {
        self.time = time1
        self.title = title1
        self.author = author1
        self.going = going1
        self.timeCreated = timeCreated1
        self.descript = descript1
        self.loc = loc1
        self.pic = pic1
        self.pub = pub1
        self.notgoing = viewed1
        self.invited = invited1
        self.key = key1
        self.cat = cat1
        self.inviterDisplay = inviterDisplay1
        self.eventid = eventid1
        self.lin = link1
    }
    
}
