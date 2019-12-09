//
//  TermsAndConditionsViewController.swift
//  OurCampus
//
//  Created by Rafael Goldstein on 1/2/19.
//  Copyright © 2019 Rafael Goldstein. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import FirebaseAuth
import WebKit

class TermsAndConditionsViewController: UIViewController, WKUIDelegate {

    var user: User?
    
    
    @IBOutlet var webView: WKWebView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let myURL = URL(string:"http://ourcampus.us.com/Terms.html")
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
        performSegue(withIdentifier: "toPrivacy", sender: nil)
    }
    
    @IBAction func disagreed(_ sender: Any) {
        let alert = UIAlertController(title: "Yikes", message: "You can't create an account without accepting our terms and conditions. Don't miss out!", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default) { (action) in
            Auth.auth().currentUser?.delete(completion: nil)
            do {
                try Auth.auth().signOut()
            }
            catch {
                // already signed out
            }
            self.navigationController?.popViewController(animated: true)
            })
        self.present(alert, animated: true, completion: nil)
    }
    
}
