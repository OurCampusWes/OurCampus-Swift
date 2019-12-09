//
//  EventHomeViewController.swift
//  OurCampus
//
//  Created by Rafael Goldstein on 6/5/19.
//  Copyright © 2019 Rafael Goldstein. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase
import FirebaseMessaging
import FirebaseStorage
import MessageUI

class EventHomeViewController: UIViewController, MFMailComposeViewControllerDelegate {
    
    @IBOutlet weak var infoStack: UIStackView!
    @IBOutlet weak var noButton: UIButton!
    @IBOutlet weak var yesButton: UIButton!
    @IBOutlet weak var goingResponse: UILabel!
    @IBOutlet var pic: UIImageView!
    @IBOutlet weak var title1: UITextField!
    @IBOutlet weak var num: UITextField!
    @IBOutlet weak var creator: UITextField!
    @IBOutlet weak var date: UITextField!
    @IBOutlet weak var noMoreEvents: UITextField!
    @IBOutlet weak var day: UILabel!
    @IBOutlet weak var month: UILabel!
    
    @IBOutlet weak var LeadingConstraint: NSLayoutConstraint!
    
    var menuShowing = false
    
    var tapRect : CGRect!
    
    @IBOutlet weak var fullName: UITextField!
    @IBOutlet weak var profilePic: UIImageView!
    
    @IBOutlet weak var contactUs: UIButton!
    
    // declare database
    var ref : DatabaseReference?
    
    // firebase account
    var user : User?
    
    var events = [AllEventModel]()
    var eventTinderFd = [AllEventModel]()
    var feed = [FeedModel]()
    
    var time : String?
    var timestamp : String?
    var descrip : String?
    var going = [String: String]()
    var notgoing = [String: String]()
    var invited = [String: String]()
    var host : String?
    var loc : String?
    var pic1 : Data?
    var pub : Bool?
    var title_s : String?
    var key = ""
    
    var inc = 0
    
    @IBOutlet weak var adView: UIView!
    @IBOutlet weak var adText: UILabel!
    
    var events_filtered = [AllEventModel]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let attrs = [
            NSAttributedString.Key.foregroundColor: UIColor(red:0.77, green:0.12, blue:0.23, alpha:1.0),
            NSAttributedString.Key.font: UIFont(name: "OraqleScript", size: 50)!
        ]
        UINavigationBar.appearance().titleTextAttributes = attrs
        self.navigationItem.title = "OurCampus"
        
        goingResponse.isHidden = true
        LeadingConstraint.constant = -348
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToSwipeGesture))
        swipeRight.direction = UISwipeGestureRecognizer.Direction.right
        self.view.addGestureRecognizer(swipeRight)
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToSwipeGesture))
        swipeLeft.direction = UISwipeGestureRecognizer.Direction.left
        self.view.addGestureRecognizer(swipeLeft)
        
        tapRect = CGRect(origin: CGPoint(x:348, y:0), size: UIScreen.main.bounds.size)
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.respondToTap))
        self.view.addGestureRecognizer(tap)
        
        contactUs.addTarget(self, action: #selector(self.respondToContact), for: .touchUpInside)
        
        ref = Database.database().reference()
        user = Auth.auth().currentUser
        self.getEventList()
        
        // Do any additional setup after loading the view.
        setUpLeadPic()
        
        pic.isHidden = true
        noMoreEvents.isHidden = false
        infoStack.isHidden = true
        yesButton.isHidden = true
        noButton.isHidden = true
        
        // set up ad view
        setUpAdView()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        getEventList()
        getUserInfo()
        getTabBarBadge()
        self.tabBarController?.tabBar.isHidden = false
        // check if user has pro pic
        let userid = user?.uid
        // get display name
        self.ref?.child("Users/" + userid!).observeSingleEvent(of: .value, with: {(snapshot) in
            if snapshot.childrenCount > 0 {
                let infoObj = snapshot.value as? [String:AnyObject]
                let alt = infoObj?["user"] as! String
                let u = infoObj?["display"] as? String ?? alt
                if u.contains("@") {
                    self.performSegue(withIdentifier: "toAddInfo", sender: nil)
                }
                else {
                    self.ref?.child("Users/" + userid!).observeSingleEvent(of: .value, with: {(snapshot) in
                        if snapshot.childrenCount > 0 {
                            let infoObj = snapshot.value as? [String:AnyObject]
                            let alt = infoObj?["user"] as! String
                            let u = infoObj?["display"] as? String ?? alt
                            self.fullName.text = u
                            
                            // Get a reference to the storage service using the default Firebase App
                            let storage = Storage.storage()
                            
                            // Create a storage reference from our storage service
                            let storageRef = storage.reference()
                            // Create a reference to the file you want to download
                            let islandRef = storageRef.child("users/" + userid! + ".png")
                            var image_decode = UIImage()
                            // Download in memory with a maximum allowed size of 1MB (1 * 1024 * 1024 bytes)
                            islandRef.getData(maxSize: 1 * 1024 * 1024) { data, error in
                                if let error = error {
                                    // Uh-oh, an error occurred!
                                } else {
                                    // Data for "images/island.jpg" is returned
                                    image_decode = UIImage(data: data!)!
                                    self.profilePic.image =  self.resizeImage(image: image_decode, newWidth: 50.0)
                                    self.profilePic.contentMode = UIView.ContentMode.scaleAspectFill
                                    self.profilePic.clipsToBounds = true
                                    self.profilePic.layer.cornerRadius = 25.0
                                    self.profilePic.sizeToFit()
                                }
                            }
                        }
                    })
                }
            }
        })
    }
    
    @IBAction func toTerms(_ sender: Any) {
        performSegue(withIdentifier: "toTerms", sender: nil)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        navigationController?.setNavigationBarHidden(false, animated: false)
        self.tabBarController?.tabBar.isHidden = false
        LeadingConstraint.constant = -348
        menuShowing = false
        
        if segue.destination is SingleEventViewController
        {
            let vc = segue.destination as? SingleEventViewController
            vc?.event = eventTinderFd[inc]
            vc?.picture = pic1
            vc?.event_id = eventTinderFd[inc].key
        }
    }
    
    @objc func respondToContact() {
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
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    
    func setUpAdView() {
        adView.layer.borderWidth = 5
        adView.layer.borderColor = UIColor(red:0.76, green:0.26, blue:0.31, alpha:1.0).cgColor
        adText.textColor = UIColor(red:0.76, green:0.26, blue:0.31, alpha:1.0)
        self.ref?.child("Advertise").observeSingleEvent(of: .value, with: {(snapshot) in
            if snapshot.childrenCount > 0 {
                let infoObj = snapshot.value as? [String:AnyObject]
                let txt = infoObj?["bottom"] as! String
                self.adText.text = txt
            }
        })
    }
    
    func getSchedule() {
        // filter events list
        for i in events {
            if (i.going?.keys.contains(user!.uid))! {
                events_filtered.append(i)
            }
        }
        // sort by new
        events_filtered = events_filtered.sorted(by: {(a, b) -> Bool in
            if let d1 = a.time {
                if let d2 = b.time {
                    return d1 < d2
                }
                return false
            }
            return false
        })
    }
    
    func getToken() {
        InstanceID.instanceID().instanceID { (result, error) in
            if let error = error {
                print("Error fetching remote instance ID: \(error)")
            } else if let result = result {
                print("Remote instance ID token: \(result.token)")
                let token  = result.token
                let upd = ["token": token] as [AnyHashable : Any]
                self.ref?.child("Users/" + self.user!.uid).updateChildValues(upd)
            }
        }
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
                self.fullName.text = u
                
                // Get a reference to the storage service using the default Firebase App
                let storage = Storage.storage()
                
                // Create a storage reference from our storage service
                let storageRef = storage.reference()
                // Create a reference to the file you want to download
                let islandRef = storageRef.child("users/" + self.user!.uid + ".png")
                var image_decode = UIImage()
                // Download in memory with a maximum allowed size of 1MB (1 * 1024 * 1024 bytes)
                islandRef.getData(maxSize: 1 * 1024 * 1024) { data, error in
                    if let error = error {
                        // Uh-oh, an error occurred!
                    } else {
                        // Data for "images/island.jpg" is returned
                        
                        image_decode = UIImage(data: data!)!
                        self.profilePic.image =  self.resizeImage(image: image_decode, newWidth: 50.0)
                        self.profilePic.contentMode = UIView.ContentMode.scaleAspectFill
                        self.profilePic.clipsToBounds = true
                        self.profilePic.layer.cornerRadius = 25.0
                        self.profilePic.sizeToFit()
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
    
    
    
    func getDisplayDate(timestamp: String) -> String {
        let dateVar = Date.init(timeIntervalSince1970: TimeInterval(timestamp)!/1000)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E, MMM d, h:mm a"
        
        return dateFormatter.string(from: dateVar)
    }
    
    func refreshEventsDisplay() {
        if eventTinderFd.count == inc {
            pic.isHidden = true
            noMoreEvents.isHidden = false
            infoStack.isHidden = true
            yesButton.isHidden = true
            noButton.isHidden = true
            goingResponse.isHidden = true
        }
        else {
            noMoreEvents.isHidden = true
            infoStack.isHidden = false
            pic.isHidden = false
            yesButton.isHidden = false
            noButton.isHidden = false
            let event_current = eventTinderFd[inc]
            going = event_current.going ?? [:]
            notgoing = event_current.notgoing ?? [:]
            goingResponse.isHidden = true
            
            time = event_current.time
            timestamp = event_current.timeCreated
            descrip = event_current.descript
            host = event_current.author
            loc = event_current.loc
            pic1 = event_current.pic
            pub = event_current.pub
            title_s = event_current.title
            key = event_current.key!
            
            title1.text = title_s!
            if going.count == 1 {
                num.text = "✈️ " + String(going.count) + " is going"
            }
            else {
                num.text = "✈️ " + String(going.count) + " are going"
            }
            
            // set up time stuff
            let full_date = getDisplayDate(timestamp: time!)
            let splitStr = full_date.components(separatedBy: ",")
            let monthDay = splitStr[1].components(separatedBy: " ")
            day.text = monthDay[2]
            day.adjustsFontSizeToFitWidth = true 
            month.text = monthDay[1]
            let restOfTime = splitStr[0] + "," + splitStr[2]
            date.text = "🕒 " + restOfTime
            
            self.creator.text = "✏️ Hosted by " + event_current.inviterDisplay!
            
            // Get a reference to the storage service using the default Firebase App
            let storage = Storage.storage()
            
            // Create a storage reference from our storage service
            let storageRef = storage.reference()
            // Create a reference to the file you want to download
            let islandRef = storageRef.child("events/" + event_current.eventid! + ".png")
            var image_decode = Data()
            // Download in memory with a maximum allowed size of 1MB (1 * 1024 * 1024 bytes)
            islandRef.getData(maxSize: 1 * 1024 * 1024) { data, error in
                if let error = error {
                    // Uh-oh, an error occurred!
                } else {
                    self.pic.image = UIImage(data: data!)
                    self.pic1 = data!
                }
            }
        }
    }
    
    @IBAction func goingTapped(_ sender: Any) {
        self.yesButton.isHidden = true
        self.noButton.isHidden = true
        self.goingResponse.text = "GOING!"
        self.goingResponse.textColor = .green
        self.goingResponse.isHidden = false
        
        self.ref?.child("Events/" + key).observeSingleEvent(of: .value, with: {(snapshot) in
            if snapshot.childrenCount > 0 {
                // if event hasn't been deleted update going list
                // update events branch
                var current_going = self.going
                var viewed = self.notgoing
                current_going[self.user!.uid] = "nil"
                viewed[self.user!.uid] = "nil"
                
                let upd = ["going": current_going, "viewed": viewed] as [AnyHashable : Any]
                
                self.ref?.child("Events/" + self.key).updateChildValues(upd)
                
                // add to feed if event is public and user is not incognito
                if self.pub! {
                    self.ref?.child("Users/" + self.user!.uid).observeSingleEvent(of: .value, with: {(snapshot) in
                        if snapshot.childrenCount > 0 {
                            let infoObj = snapshot.value as? [String:AnyObject]
                            let val = infoObj?["incognito"] as! Bool
                            // if incognito mode is off, then add to feed
                            if !val {
                                // update feed branch
                                let upd2 = ["eventid": self.key, "timestamp": [".sv": "timestamp"], "userid": self.user?.uid] as [AnyHashable: Any]
                                self.ref?.child("Feed/" + self.key + "/" + self.user!.uid).updateChildValues(upd2)
                            }
                        }
                    })
                }
            }
            else {
                self.refreshEventsDisplay()
            }
        })
        // add user to going list
        self.inc += 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Put your code which should be executed with a delay here
            self.refreshEventsDisplay()
        }
        
    }
    
    @IBAction func notGoingTapped(_ sender: Any) {
        self.yesButton.isHidden = true
        self.noButton.isHidden = true
        self.goingResponse.text = "NOT GOING!"
        self.goingResponse.textColor = .red
        self.goingResponse.isHidden = false
        // if event is still there then update it
        self.ref?.child("Events/" + key).observeSingleEvent(of: .value, with: {(snapshot) in
            if snapshot.childrenCount > 0 {
                var current_going = self.notgoing
                current_going[self.user!.uid] = "nil"
                
                let upd = ["viewed": current_going] as [AnyHashable : Any]
                
                self.ref?.child("Events/" + self.key).updateChildValues(upd)
            }
        })
        // add user to not going list
        self.inc += 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Put your code which should be executed with a delay here
            self.refreshEventsDisplay()
        }
    }
    
    func getEventList() {
        self.events.removeAll()
        self.refreshEventsDisplay()
        var tempEvents = [AllEventModel]()
        
        self.ref?.child("Events/").observeSingleEvent(of: .value, with: {(snapshot) in
            if snapshot.childrenCount > 0 {
                self.ref?.child("Users/").observeSingleEvent(of: .value, with: {(snapshot2) in
                    if snapshot2.childrenCount > 0 {
                        for x in snapshot.children.allObjects as! [DataSnapshot] {
                            let infoObj = x.value as? [String: AnyObject]
                            let time = String(format: "%@", infoObj?["eventtime"] as! CVarArg)
                            let timestamp = String(format: "%@", infoObj?["timeposted"] as! CVarArg)
                            let description = infoObj?["description"] as! String
                            let going = infoObj?["going"] as! [String: String]
                            let viewed = infoObj?["viewed"] as! [String: String]
                            let invited = infoObj?["invited"] as! [String: String]
                            let host = infoObj?["host"] as! String
                            let loc = infoObj?["location"] as! String
                            let pub = infoObj?["public"] as! Bool
                            let title = infoObj?["title"] as! String
                            let cat = infoObj?["category"] as! String
                            var link1 = infoObj?["link"]
                            var link2 = "placehold"
                            if link1 != nil {
                                link2 = link1 as! String
                            }
                            
                            // check to see if event has passed
                            // get current date
                            let d8 = Date()
                            var d8ms = Double(d8.timeIntervalSince1970)
                            // add 3 hours and convert to ms
                            // so now we have current time in ms
                            var nowTime = (d8ms - 10800) * 1000
                            
                            var eTime = 0.0
                            if let timeD = Double(time) {
                                eTime = timeD
                            }
                            
                            // if event has started dont show it!
                            var passed = eTime < nowTime
                            
                            // no repeats
                            var contains = false
                            for e in tempEvents {
                                if e.timeCreated == timestamp {
                                    contains = true
                                }
                            }
                            
                            // if viewed dont show
                            var viewedAlready = false
                            for i in viewed {
                                if i.key == self.user?.uid {
                                    viewedAlready = true
                                }
                            }
                            
                            // if it is not added, then append it!
                            if !contains {
                                if !passed {
                                    if !viewedAlready {
                                    // get host's display name
                                    if snapshot2.childSnapshot(forPath: host + "/display").exists() {
                                        let h = snapshot2.childSnapshot(forPath: host + "/display").value! as! String
                                        let event1 = AllEventModel(pub1: pub, pic1: Data(), loc1: loc, descript1: description, timeCreated1: timestamp, time1: time, title1: title, author1: host, going1: going, viewed1: viewed, invited1: invited, key1: x.key, cat1: cat, inviterDisplay1: h, eventid1: x.key, link1: link2)
                                        tempEvents.append(event1)
                                    }
                                }
                                    
                                }
                            }
                        }
                        
                        tempEvents = tempEvents.sorted(by: {(a, b) -> Bool in
                            if let d1 = a.going?.count {
                                if let d2 = b.going?.count {
                                    return d1 > d2
                                }
                                return false
                            }
                            return false
                        })
                        self.eventTinderFd = tempEvents
                        self.refreshEventsDisplay()
                    }
                })
            }
        })
    }
    
    @IBAction func toFeed(_ sender: Any) {
        performSegue(withIdentifier: "toFeed", sender: nil)
    }
    
    @IBAction func toPrivacy(_ sender: Any) {
        performSegue(withIdentifier: "toPrivacy", sender: nil)
    }
    
    @IBAction func goToScheduleController(_ sender: Any) {
        performSegue(withIdentifier: "toSchedule", sender: nil)
    }
    
    // tap for menu
    @objc func respondToTap(gesture: UIGestureRecognizer) {
        if menuShowing {
            let p = gesture.location(in: self.view)
            if tapRect.contains(p) {
                LeadingConstraint.constant = -348
                UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseIn, animations: {
                    self.view.layoutIfNeeded()
                }, completion: nil)
                navigationController?.setNavigationBarHidden(false, animated: false)
                self.tabBarController?.tabBar.isHidden = false
                menuShowing = !menuShowing
            }
        }
        else {
            // do nothing
        }
    }
    
    // tap for main pic
    @IBAction func tappedPic(_ sender: UITapGestureRecognizer) {
        performSegue(withIdentifier: "toEvent", sender: nil)
    }
    
    @objc func respondToSwipeGesture(gesture: UIGestureRecognizer) {
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            switch swipeGesture.direction {
            case UISwipeGestureRecognizer.Direction.right:
                LeadingConstraint.constant = 0
                UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseOut, animations: {
                    self.view.layoutIfNeeded()
                }, completion: nil)
                navigationController?.setNavigationBarHidden(true, animated: false)
                self.tabBarController?.tabBar.isHidden = true
                menuShowing = !menuShowing
            case UISwipeGestureRecognizer.Direction.left:
                LeadingConstraint.constant = -348
                UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseIn, animations: {
                    self.view.layoutIfNeeded()
                }, completion: nil)
                navigationController?.setNavigationBarHidden(false, animated: false)
                self.tabBarController?.tabBar.isHidden = false
                menuShowing = !menuShowing
            default:
                break
            }
        }
    }
    
    func setUpProPic(){
        self.profilePic.layer.cornerRadius = 25.0
        self.profilePic.clipsToBounds = true
        self.profilePic.sizeToFit()
    }
    
    @IBAction func addEvent(_ sender: Any) {
        self.performSegue(withIdentifier: "toCreate", sender: nil)
    }
    
    @IBAction func openMenu(_ sender: Any) {
        if menuShowing {
            LeadingConstraint.constant = -348
            UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseIn, animations: {
                self.view.layoutIfNeeded()
            }, completion: nil)
            navigationController?.setNavigationBarHidden(false, animated: false)
            self.tabBarController?.tabBar.isHidden = false
        }
        else {
            LeadingConstraint.constant = 0
            UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseOut, animations: {
                self.view.layoutIfNeeded()
            }, completion: nil)
            navigationController?.setNavigationBarHidden(true, animated: false)
            self.tabBarController?.tabBar.isHidden = true
        }
        menuShowing = !menuShowing
    }
    
    func setUpLeadPic() {
        // the color of the shadow
        self.pic.layer.shadowColor = UIColor.darkGray.cgColor
        
        // the shadow will be 5pt right and 5pt below the image view
        // negative value will place it on left / above of the image view
        self.pic.layer.shadowOffset = CGSize(width: 5.0, height: 5.0)
        
        // how long the shadow will be. The longer the shadow, the more blurred it will be
        self.pic.layer.shadowRadius = 10.0
        
        // opacity of the shadow
        self.pic.layer.shadowOpacity = 0.9
        self.pic.layer.cornerRadius = 25.0
        self.pic.clipsToBounds = true
    }
    
    @IBAction func goToAllEvents(_ sender: Any) {
        menuShowing = !menuShowing
        LeadingConstraint.constant = -348
        self.view.layoutIfNeeded()
        self.tabBarController?.tabBar.isHidden = false
        navigationController?.setNavigationBarHidden(false, animated: false)
        self.performSegue(withIdentifier: "toAllEvents", sender: nil)
    }
    
    
    @IBAction func toSettings(_ sender: Any) {
        self.performSegue(withIdentifier: "toSettings", sender: nil)
    }
}
extension UIImage {
    enum JPEGQuality: CGFloat {
        case lowest  = 0
        case low     = 0.25
        case medium  = 0.5
        case high    = 0.75
        case highest = 1
    }
    
    /// Returns the data for the specified image in JPEG format.
    /// If the image object’s underlying image data has been purged, calling this function forces that data to be reloaded into memory.
    /// - returns: A data object containing the JPEG data, or nil if there was a problem generating the data. This function may return nil if the image has no data or if the underlying CGImageRef contains data in an unsupported bitmap format.
    func jpeg(_ jpegQuality: JPEGQuality) -> Data? {
        return jpegData(compressionQuality: jpegQuality.rawValue)
    }
}
