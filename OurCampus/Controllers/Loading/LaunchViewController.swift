//
//  LaunchViewController.swift
//  OurCampus
//
//  Created by Rafael Goldstein on 12/29/18.
//  Copyright © 2018 Rafael Goldstein. All rights reserved.
//

import UIKit
import Kanna
import Alamofire
import Firebase
import FirebaseDatabase

class LaunchViewController: UIViewController {
    
    let network: NetworkManager = NetworkManager.sharedInstance
    var timer = Timer()
    
    
    var ref : DatabaseReference?
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        // If the network is unreachable show the offline page
        NetworkManager.isUnreachable { _ in
            self.showOfflinePage()
        }
            
        NetworkManager.isReachable { _ in
            self.showMainPage()
        }
        
    }
    
    private func showOfflinePage() -> Void {
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "NetworkUnavailable", sender: self)
        }
    }
    
    private func showMainPage() -> Void {
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
            self.performSegue(withIdentifier: "toSignIn", sender: self)
        })
        
        
    }
    
}
