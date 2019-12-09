//
//  PrivacyViewController.swift
//  OurCampus
//
//  Created by Rafael Goldstein on 1/27/19.
//  Copyright © 2019 Rafael Goldstein. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase
import WebKit

class PrivacyViewController: UIViewController, WKUIDelegate {

    var user: User?
    
    @IBOutlet var webView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.isNavigationBarHidden = false
        let myURL = URL(string:"http://ourcampus.us.com/PrivacyPolicy.html")
        let myRequest = URLRequest(url: myURL!)
        webView.load(myRequest)
        user = Auth.auth().currentUser
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("OK")
        self.navigationController?.isNavigationBarHidden = false
    }
    
    
    @IBAction func agreed(_ sender: Any) {
        // present auth vc
        let current = UIDevice.current
        let name = current.name
        let os = current.systemVersion
        let u = Auth.auth().currentUser
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short)
        let ref = Database.database().reference().child("Users/")
        let userUpdate = ["user": u!.email, "name": name, "os": os, "time": timestamp, "incognito": false] as [String : Any]
        ref.child(u!.uid).updateChildValues(userUpdate as [AnyHashable : Any])
        performSegue(withIdentifier: "toMain", sender: nil)
    }
    
    @IBAction func disagreed(_ sender: Any) {
        let alert = UIAlertController(title: "Yikes", message: "You can't create an account without accepting our privacy policy. Don't miss out!", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default) { (action) in
            Auth.auth().currentUser?.delete(completion: nil)
            do {
                try Auth.auth().signOut()
            }
            catch {
                // already signed out
            }
            self.navigationController?.popToRootViewController(animated: true)
        })
        self.present(alert, animated: true, completion: nil)
    }
}
