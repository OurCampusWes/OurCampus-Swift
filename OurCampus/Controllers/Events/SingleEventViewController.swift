//
//  SingleEventViewController.swift
//  OurCampus
//
//  Created by Rafael Goldstein on 7/10/19.
//  Copyright © 2019 Rafael Goldstein. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage

class SingleEventViewController: UIViewController {
    
    @IBOutlet weak var title1: UITextField!
    @IBOutlet weak var author: UITextField!
    @IBOutlet weak var descrip: UITextView!
    @IBOutlet weak var time: UITextField!
    @IBOutlet weak var loc: UITextField!
    @IBOutlet weak var going: UITextField!
    @IBOutlet weak var goingLabel: UILabel!
    @IBOutlet weak var noButton: UIButton!
    @IBOutlet weak var yesButton: UIButton!
    
    var event : AllEventModel?
    
    var title_s : String?
    var auth : String?
    var desc : String?
    var ti : String?
    var lo : String?
    var go = [String: String]()
    var notgo = [String: String]()
    var inv = [String: String]()
    var key = ""
    var ho = ""
    var picture : Data?
    var pub : Bool?
    var tstamp : String?
    var cat : String?
    var link1 : String?
    
    // declare database
    var ref : DatabaseReference?
    
    // firebase account
    var user : User?
    
    var event_id : String?
    
    var host = false
    
    var mili_stamp = ""
    
    @IBOutlet weak var pic: UIImageView!
    
    @IBOutlet weak var loadingScreen: UIView!
    @IBOutlet weak var loadingLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let attrs = [
            NSAttributedString.Key.foregroundColor: UIColor(red:0.77, green:0.12, blue:0.23, alpha:1.0),
            NSAttributedString.Key.font: UIFont(name: "OraqleScript", size: 50)!
        ]
        UINavigationBar.appearance().titleTextAttributes = attrs
        self.navigationItem.title = "Event"
        
        ref = Database.database().reference()
        // Do any additional setup after loading the view.
        user = Auth.auth().currentUser
        getGoingInfo()
        getEventInfo()
        
        going.addTarget(self, action: #selector(myTargetFunction), for: .touchDown)
        loadingScreen.isHidden = false
        
        // loading label
        loadingLabel.font = UIFont(name: "Raleway", size: 20)!
        loadingLabel.textColor = UIColor(red:0.77, green:0.12, blue:0.23, alpha:1.0)
        loadingLabel.text = "Loading.."
        
        // make description fit
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        getEventInfo()
        getTabBarBadge()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is CreateEventViewController {
            let vc = segue.destination as? CreateEventViewController
            vc?.tit = title1.text
            vc?.lo = loc.text
            vc?.ti = time.text
            vc?.pic = (pic.image?.pngData())!
            vc?.desc = descrip.text
            vc?.publicEvent = pub!
            vc?.invited = inv
            vc?.going = go
            vc?.viewed = notgo
            vc?.key = key
            if let amount = tstamp as? String {
                let am = Double(amount)
                vc?.final_stamp = am
            }
            vc?.edit = true
            vc?.mili_stamp = ti!
            vc?.category = cat
            vc?.link1 = link1
        }
        
        if segue.destination is GoingTableViewController {
            let vc = segue.destination as? GoingTableViewController
            var temp = [String]()
            for i in go.keys {
                temp.append(i)
            }
            vc?.going = temp
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
    
    @objc func myTargetFunction(textField: UITextField) {
        performSegue(withIdentifier: "toGoing", sender: nil)
    }
    
    @IBAction func picTapped(_ sender: Any) {
        if link1 != nil {
            guard let url = URL(string: self.link1!) else { return }
            UIApplication.shared.open(url)
        }
    }
    
    func getEventInfo() {
        self.ref?.child("Events/" + event_id!).observeSingleEvent(of: .value, with: {(snapshot3) in
            if snapshot3.childrenCount > 0 {
                let infoObj = snapshot3.value as? [String: AnyObject]
                
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
                let linkDb = infoObj?["link"]
                var link1 = infoObj?["link"]
                var link2 = "placehold"
                if link1 != nil {
                    link2 = link1 as! String
                }
                
                // get image
                // Get a reference to the storage service using the default Firebase App
                let storage = Storage.storage()
                
                // Create a storage reference from our storage service
                let storageRef = storage.reference()
                // Create a reference to the file you want to download
                let islandRef = storageRef.child("events/" + self.event_id! + ".png")
                var image_decode = Data()
                // Download in memory with a maximum allowed size of 1MB (1 * 1024 * 1024 bytes)
                islandRef.getData(maxSize: 1 * 1024 * 1024) { data, error in
                    if let error = error {
                        // Uh-oh, an error occurred!
                    } else {
                        // Data for "images/island.jpg" is returned
                        image_decode = data!
                        self.event = AllEventModel(pub1: pub, pic1: image_decode, loc1: loc, descript1: description, timeCreated1: timestamp, time1: time, title1: title, author1: host, going1: going, viewed1: viewed, invited1: invited, key1: self.event_id!, cat1: cat, inviterDisplay1: "event", eventid1: "", link1: link2)
                        // set up pic
                        self.pic.image = UIImage(data: image_decode)
                        // rest
                        self.auth = self.event?.author
                        self.title_s = self.event?.title
                        self.desc = self.event?.descript
                        self.ti = self.event?.time
                        self.lo = self.event?.loc
                        self.go = self.event!.going!
                        self.key = self.event!.key!
                        self.notgo = self.event!.notgoing!
                        self.inv = self.event!.invited!
                        self.ho = self.event!.author!
                        self.pub = self.event?.pub
                        self.tstamp = self.event?.timeCreated
                        self.cat = self.event?.cat
                        
                        self.link1 = link2 
                        
                        self.mili_stamp = self.event!.time!
                        
                        self.title1.text = self.title_s
                        let id = self.auth ?? "na"
                        self.ref?.child("Users/" + id).observeSingleEvent(of: .value, with: {(snapshot) in
                            if snapshot.childrenCount > 0 {
                                let infoObj = snapshot.value as? [String:AnyObject]
                                let u = infoObj?["display"]
                                var email = infoObj?["user"] as! String
                                var alt = ""
                                if u != nil {
                                    alt = u as! String
                                    self.author.text = "By " + alt
                                }
                                else {
                                    let arr = email.components(separatedBy: "@")
                                    email = arr[0]
                                    self.author.text = "By " + email
                                }
                            }
                        })
                        self.descrip.text = self.desc
                        self.time.text = self.getDisplayDate(timestamp: self.ti!)
                        self.loc.text = self.lo
                        if self.go.count == 1 {
                            self.going.text = String(self.go.count) + " is going"
                        }
                        else {
                            self.going.text = String(self.go.count) + " are going"
                        }
                        self.getGoingInfo()
                    }
                }
            }
        })
        
        
        
    }
    
    func getDisplayDate(timestamp: String) -> String {
        let dateVar = Date.init(timeIntervalSince1970: TimeInterval(timestamp)!/1000)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E, MMM d, h:mm a"
        
        return dateFormatter.string(from: dateVar)
    }
    
    @objc func editTapped() {
        // allow user to make changes
        performSegue(withIdentifier: "toEdit", sender: nil)
    }
    
    @objc func reportEvent() {
        let alert = UIAlertController(title: "Reported events will be reviewed by our moderators", message: "Please inform us if this event is spam, innapropriate, etc.", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Report Event", style: UIAlertAction.Style.destructive) { (action) in
            let upd = ["user": self.user?.uid] as [AnyHashable : Any]
            
            self.ref?.child("ReportedEvents/" + self.key).updateChildValues(upd)
        })
        self.present(alert, animated: true, completion: nil)
    }
    
    
    func getGoingInfo() {
        if ho == user?.uid {
            goingLabel.textColor = UIColor.black
            goingLabel.text = "You are going because you are the host!"
            yesButton.isHidden = true
            noButton.isHidden = true
            
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Edit", style: .done, target: self, action: #selector(editTapped))
        }
            
        else {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Report", style: .done, target: self, action: #selector(reportEvent))
            let uid = user?.uid ?? ""
            if go.keys.contains(uid) {
                goingLabel.textColor = UIColor.green
                goingLabel.text = "You are currently going"
            }
                
            else if notgo.keys.contains(uid) {
                goingLabel.textColor = UIColor.red
                goingLabel.text = "You are currently not going"
            }
                
            else {
                goingLabel.textColor = UIColor.black
                goingLabel.text = "Are you down?"
            }
            
        }
        
        self.loadingScreen.isHidden = true
    }
    
    @IBAction func noTapped(_ sender: Any) {
        
        if goingLabel.text != "You are currently not going" {
            self.ref?.child("Events/" + key).observeSingleEvent(of: .value, with: {(snapshot) in
                if snapshot.childrenCount > 0 {
                    // update events branch
                    var current_going = self.go
                    if let val = current_going.removeValue(forKey: self.user!.uid) {
                        self.go.removeValue(forKey: self.user!.uid)
                    }
                    
                    var current_read = self.notgo
                    current_read[self.user!.uid] = "nil"
                    let upd = ["viewed": current_read, "going": current_going] as [AnyHashable : Any]
                    
                    self.ref?.child("Events/" + self.key).updateChildValues(upd)
                    self.goingLabel.textColor = UIColor.red
                    self.goingLabel.text = "You are currently not going"
                }
            })
           
        }
    }
    
    @IBAction func yesTapped(_ sender: Any) {
        if goingLabel.text != "You are currently going" {
            self.ref?.child("Events/" + key).observeSingleEvent(of: .value, with: {(snapshot) in
                if snapshot.childrenCount > 0 {
                    var current_going = self.go
                    current_going[self.user!.uid] = "nil"
                    var current_read = self.notgo
                    current_read[self.user!.uid] = "nil"
                    let upd = ["going": current_going, "viewed": current_read] as [AnyHashable : Any]
                    
                    self.ref?.child("Events/" + self.key).updateChildValues(upd)
                    
                    // if event is public add to feed
                    
                    if self.pub! {
                        // update feed branch
                        self.ref?.child("Users/" + self.user!.uid).observeSingleEvent(of: .value, with: {(snapshot) in
                            if snapshot.childrenCount > 0 {
                                let infoObj = snapshot.value as? [String:AnyObject]
                                let val = infoObj?["incognito"] as! Bool
                                // if incognito mode is off, then add to feed
                                if !val {
                                    // update feed branch
                                    let upd2 = ["eventid": self.key, "timestamp": [".sv": "timestamp"], "userid": self.user?.uid] as [AnyHashable: Any]
                                    self.ref?.child("Feed/" + self.key + "/" + self.user!.uid).updateChildValues(upd2)
                                    self.goingLabel.textColor = UIColor.green
                                    self.goingLabel.text = "You are currently going"
                                }
                            }
                        })
                    }
                }
            })
            
        }
    }
}
