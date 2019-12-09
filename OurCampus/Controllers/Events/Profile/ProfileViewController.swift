//
//  ProfileViewController.swift
//  OurCampus
//
//  Created by Rafael Goldstein on 9/19/19.
//  Copyright © 2019 Rafael Goldstein. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseStorage
import FirebaseDatabase
import MessageUI

class ProfileViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, MFMailComposeViewControllerDelegate {
   
    var ref : DatabaseReference?
    var user : User?
    
    @IBOutlet var username: UILabel!
    @IBOutlet var proPic: UIImageView!
    @IBOutlet var dispName: UILabel!
    
    @IBOutlet var optionsTable: UITableView!
    
    var buttonNames = ["Feed", "My Schedule", "My Reviews", "Subscribe to Class", "Settings", "Contact Us", "Terms", "Privacy"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Profile"

        ref = Database.database().reference()
        user = Auth.auth().currentUser
        
        let r = UIColor(red:0.77, green:0.12, blue:0.23, alpha:1.0)
        self.setGradientBackground(colorTop: r, colorBottom: .clear)
        
        optionsTable.backgroundColor = UIColor.clear
        optionsTable.allowsSelection = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.isNavigationBarHidden = true
        getTabBarBadge()
        getUserInfo()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        navigationController?.isNavigationBarHidden = false
        if segue.destination is OldPostsViewController
        {
            let vc = segue.destination as? OldPostsViewController
            vc?.user = user?.email ?? ""
        }
        
    }
    
    @IBAction func notisTapped(_ sender: Any) {
        self.performSegue(withIdentifier: "toNotifications", sender: nil)
    }
    
    @IBAction func buttonTapped(_ sender: UIButton) {
        if sender.tag == 0 {
            self.performSegue(withIdentifier: "toFeed", sender: nil)
        }
        else if sender.tag == 1 {
            self.performSegue(withIdentifier: "toSchedule", sender: nil)
            
        }
        else if sender.tag == 2 {
            self.performSegue(withIdentifier: "toOld", sender: nil)
//
        }
        else if sender.tag == 3 {
            self.performSegue(withIdentifier: "toSubscribe", sender: nil)
//                      let alert = UIAlertController(title: "Hold up", message: "This feature will be available for next semester's preregistration", preferredStyle: UIAlertController.Style.alert)
//                      alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
//                      self.present(alert, animated: true, completion: nil)
            
        }
        else if sender.tag == 4 {
            self.performSegue(withIdentifier: "toSettings", sender: nil)
        }
        else if sender.tag == 5 {
            if !MFMailComposeViewController.canSendMail() {
                print("Mail services are not available")
                return
            }
            else {
                let composeVC = MFMailComposeViewController()
                composeVC.mailComposeDelegate = self
                // Configure the fields of the interface.
                composeVC.setToRecipients(["support@ourcampus.us.com"])
                composeVC.setSubject("Hello!")
                // Present the view controller modally.
                self.present(composeVC, animated: true, completion: nil)
            }
           
        }
        else if sender.tag == 6 {
             self.performSegue(withIdentifier: "toTerms", sender: nil)
            
        }
        else if sender.tag == 7 {
            self.performSegue(withIdentifier: "toPrivacy", sender: nil)
            
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func getUserInfo() {
        self.ref?.child("Users/" + user!.uid).observeSingleEvent(of: .value, with: {(snapshot) in
            if snapshot.childrenCount > 0 {
                let infoObj = snapshot.value as? [String:AnyObject]
                let alt = infoObj?["user"] as! String
                var u = infoObj?["display"] as? String ?? alt
                if u.contains("@") {
                    let arr = u.components(separatedBy: "@")
                    u = arr[0]
                    
                }
                self.username.text = alt.components(separatedBy: "@")[0]
                self.dispName.text = u
                
                // Get a reference to the storage service using the default Firebase App
                let storage = Storage.storage()
                
                // Create a storage reference from our storage service
                let storageRef = storage.reference()
                // Create a reference to the file you want to download
                let islandRef = storageRef.child("users/" + self.user!.uid + ".png")
                var image_decode = UIImage()
                // Download in memory with a maximum allowed size of 1MB (1 * 1024 * 1024 bytes)
                islandRef.getData(maxSize: 10 * 1024 * 1024) { data, error in
                    if let error = error {
                        // Uh-oh, an error occurred!
                    } else {
                        // Data for "images/island.jpg" is returned
                        
                        image_decode = UIImage(data: data!)!
                        self.proPic.image =  self.resizeImage(image: image_decode, newWidth: 50.0)
                        self.proPic.contentMode = UIView.ContentMode.scaleAspectFill
                        self.proPic.clipsToBounds = true
                        self.proPic.layer.cornerRadius = 25.0
                        self.proPic.sizeToFit()
                    }
                }
            }
        })
    }
    
    func resizeImage(image: UIImage, newWidth: CGFloat) -> UIImage {
        
        let scale = newWidth / image.size.width
        let newHeight = image.size.height * scale
        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
        image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    
    func setGradientBackground(colorTop: UIColor, colorBottom: UIColor) {
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [colorBottom.cgColor, colorTop.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 1.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.locations = [0, 1]
        gradientLayer.frame = UIScreen.main.bounds
        
        view.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return buttonNames.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "settings", for: indexPath) as! SettingsTableViewCell
        
        cell.button1.setTitle(buttonNames[indexPath.row], for: .normal)
        cell.button1.tag = indexPath.row
        
        
        cell.cell.backgroundColor = .clear
       
        cell.backgroundColor = .clear
//        cell.cell.layer.borderWidth = 1.0
//        cell.cell.layer.borderColor = UIColor(red:0.77, green:0.12, blue:0.23, alpha:1.0).cgColor
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 45
    }
    
    
    func getTabBarBadge() {
        if let tabItems = tabBarController?.tabBar.items {
            // In this case we want to modify the badge number of the third tab:
            let tabItem = tabItems[2]
            var notis = 0
            
            let path = "Users/" + self.user!.uid + "/Notifications"
            self.ref?.child(path).observeSingleEvent(of: .value, with: {(snapshot) in
                if snapshot.childrenCount > 0 {
                    for e in snapshot.children.allObjects as! [DataSnapshot] {
                        let infoObj = e.value as? [String: AnyObject]
                        let eventid = infoObj?["eventid"] as! String
                        let viewed = infoObj?["viewed"] as! Bool
                        // get event display name
                        self.ref?.child("Events/" + eventid).observeSingleEvent(of: .value, with: {(snapshot3) in
                            if snapshot3.childrenCount > 0 {
                                let infoObj2 = snapshot3.value as? [String: AnyObject]
                                let eventtitle = infoObj2?["title"] as! String
                                if !viewed {
                                    notis += 1
                                }
                                if notis == 0 {
                                    tabItem.badgeValue = nil
                                }
                                else {
                                    tabItem.badgeValue = String(notis)
                                }
                            }
                        })
                    }
                }
            })
        }
    }
    
    
}
