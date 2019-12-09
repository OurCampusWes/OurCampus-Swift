//
//  TopRatesModel.swift
//  OurCampusXcode
//
//  Created by Rafael Goldstein on 12/21/18.
//  Copyright © 2018 Rafael Goldstein. All rights reserved.
//

import Foundation

class TopRatesModel {
    
    var prof: String?
    var rate: String?
    var num: String?
    
    init(rate1: String?, prof1: String?, n: String?)
    {
        self.rate = rate1
        self.prof = prof1
        self.num = n
    }
}
