//
//  SignInViewController.swift
//  OurCampus
//
//  Created by Rafael Goldstein on 11/24/18.
//  Copyright © 2018 Rafael Goldstein. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase
import FirebaseUI

class SignInViewController: UIViewController, FUIAuthDelegate {
    
    @IBOutlet weak var createAccount: UIButton!
    @IBOutlet weak var signIn: UIButton!
    
    var authUI: FUIAuth?
    
    var profs = [String]()
    
    var profIP = "129.133.7.96"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let u = Auth.auth().currentUser
        if u != nil {
            let choppedArray = u?.email!.components(separatedBy: "@")
            let e = choppedArray![0]
            let hostN = e + ".mail.wesleyan.edu"
            let host = CFHostCreateWithName(nil,hostN as CFString).takeRetainedValue()
            CFHostStartInfoResolution(host, .addresses, nil)
            var success: DarwinBoolean = false
            if let addresses = CFHostGetAddressing(host, &success)?.takeUnretainedValue() as NSArray?,
                let theAddress = addresses.firstObject as? NSData {
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                if getnameinfo(theAddress.bytes.assumingMemoryBound(to: sockaddr.self), socklen_t(theAddress.length),
                               &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST) == 0 {
                    let numAddress = String(cString: hostname)
                    print(numAddress)
                    // this seems to be the professor's IP so if this is it don't let them in
                    if numAddress == profIP {
                        do {
                            try Auth.auth().signOut()
                            let alert = UIAlertController(title: "Unable to Sign In", message: "Only students are allowed to sign in!", preferredStyle: UIAlertController.Style.alert)
                            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                            self.present(alert, animated: true, completion: nil)
                            return
                        }
                        catch {
                            // already signed out
                        }
                    }
                    else {
                        let ref = Database.database().reference().child("Users")
                        ref.observe(.value, with: { (snapshot) in
                            if snapshot.hasChild((u?.uid)!) {
                                self.performSegue(withIdentifier: "toMain", sender: nil)
                            }
                            else {
                                return
                            }
                        })
                    }
                }
            }
            
        }
        
        createAccount.tag = 0
        signIn.tag = 1
        
        authUI = FUIAuth.defaultAuthUI()
        authUI?.delegate = self
        let providers : [FUIAuthProvider] = [FUIGoogleAuth()]
        authUI?.providers = providers
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        self.navigationController?.isNavigationBarHidden = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = true
        self.navigationController?.isToolbarHidden = true
        self.tabBarController?.tabBar.isHidden = true
    }
    
    func authUI(_ authUI: FUIAuth, didSignInWith authDataResult: AuthDataResult?, error: Error?) {
        if error == nil {
            let user = Auth.auth().currentUser?.email
            let choppedArray = user!.components(separatedBy: "@")
            let e = choppedArray[0]
            let hostN = e + ".mail.wesleyan.edu"
            let host = CFHostCreateWithName(nil,hostN as CFString).takeRetainedValue()
            CFHostStartInfoResolution(host, .addresses, nil)
            var success: DarwinBoolean = false
            
            
            if user?.hasSuffix("@wesleyan.edu") == false {
                Auth.auth().currentUser?.delete(completion: nil)
                do {
                    try Auth.auth().signOut()
                    let alert = UIAlertController(title: "Unable to Create Account", message: "Please provide an @wesleyan.edu email address", preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                } catch {
                    // already signed out
                }
            }
                
            
            else if let addresses = CFHostGetAddressing(host, &success)?.takeUnretainedValue() as NSArray?,
                let theAddress = addresses.firstObject as? NSData {
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                if getnameinfo(theAddress.bytes.assumingMemoryBound(to: sockaddr.self), socklen_t(theAddress.length),
                               &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST) == 0 {
                    let numAddress = String(cString: hostname)
                    print(numAddress)
                    // this seems to be the professor's IP so if this is it don't let them in
                    if numAddress == profIP {
                        do {
                            try Auth.auth().signOut()
                            let alert = UIAlertController(title: "Unable to Sign In", message: "Only students are allowed to sign in!", preferredStyle: UIAlertController.Style.alert)
                            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                            self.present(alert, animated: true, completion: nil)
                            return
                        }
                        catch {
                            // already signed out
                        }
                    }
                    // if its not a prof we're good!
                    else {
                        var created = false
                        let u = Auth.auth().currentUser
                        let ref = Database.database().reference().child("Users/")
                        let ref2 = ref.queryOrderedByKey()
                        ref2.observeSingleEvent(of: .value, with: {(snapshot) in
                            if snapshot.childrenCount > 0 {
                                for x in snapshot.children.allObjects as! [DataSnapshot] {
                                    let infoObj = x.value as? [String: AnyObject]
                                    let e = infoObj?["user"]
                                    if e != nil {
                                        let email = e as! String
                                        if u?.email == email {
                                            self.performSegue(withIdentifier: "toMain", sender: nil)
                                            created = true
                                        }
                                    }
                                }
                            }
                            if created == false {
                                self.performSegue(withIdentifier: "toTerms", sender: nil)
                            }
                        })
                    }
                }
            }
                
            // it's an @wesleyan email but maybe they have not accepted our terms/created an account yet
            else {
                var created = false
                let u = Auth.auth().currentUser
                let ref = Database.database().reference().child("Users/")
                let ref2 = ref.queryOrderedByKey()
                ref2.observeSingleEvent(of: .value, with: {(snapshot) in
                    if snapshot.childrenCount > 0 {
                        for x in snapshot.children.allObjects as! [DataSnapshot] {
                            let infoObj = x.value as? [String: AnyObject]
                            let e = infoObj?["user"]
                            if e != nil {
                                let email = e as! String
                                if u?.email == email {
                                    self.performSegue(withIdentifier: "toMain", sender: nil)
                                    created = true
                                }
                            }
                        }
                    }
                    if created == false {
                        self.performSegue(withIdentifier: "toTerms", sender: nil)
                    }
                })
            }
            
        }
            
        else {
            let alert = UIAlertController(title: "Unable to Create Account", message: "Only students with @wesleyan.edu emails may create accounts", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func buttonIsPressed(sender: UIButton!) {
        if sender.tag == 1  {
            if Auth.auth().currentUser == nil {
                if let authVC = authUI?.authViewController() {
                    present(authVC, animated: true, completion: nil)
                }
            }
            else {
                do {
                    try Auth.auth().signOut()
                    if let authVC = authUI?.authViewController() {
                        present(authVC, animated: true, completion: nil)
                    }
                }
                catch _ as NSError {
                    if let authVC = authUI?.authViewController() {
                        present(authVC, animated: true, completion: nil)
                    }
                }
            }
        }
        else {
            do {
                try Auth.auth().signOut()
                if let authVC = authUI?.authViewController() {
                    present(authVC, animated: true, completion: nil)
                }
            }
            catch _ as NSError {
                if let authVC = authUI?.authViewController() {
                    present(authVC, animated: true, completion: nil)
                }
            }
            
        }
        
    }
    
}
