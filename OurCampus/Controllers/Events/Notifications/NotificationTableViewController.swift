//
//  NotificationTableViewController.swift
//  OurCampus
//
//  Created by Rafael Goldstein on 8/21/19.
//  Copyright © 2019 Rafael Goldstein. All rights reserved.
//

import UIKit
import Firebase
import FirebaseMessaging
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage

class NotificationTableViewController: UITableViewController {
    
    var notifications = [NotificationModel]()
    var event : AllEventModel?
    var ref : DatabaseReference?
    var user : User?

    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        user = Auth.auth().currentUser
        
        self.navigationItem.title = "Notifications"
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action:  #selector(refreshData), for: .valueChanged)
        self.refreshControl = refreshControl
        
        self.tableView.separatorStyle = .none
        
        refreshData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
//        if notifications.count == 0 {
//            tableView.isHidden = true
//        }
//        else {
//            tableView.isHidden = false
//        }
        getTabBarBadge()
        refreshData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is SingleEventViewController {
            let vc = segue.destination as? SingleEventViewController
            vc?.event = event
            vc?.picture = event?.pic
            vc?.event_id = event?.key
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return notifications.count
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
    
    @objc private func refreshData() {
        notifications.removeAll()
        self.tableView.reloadData()
        getNotificationsRefresh()
    }
    
    func getNotificationsRefresh() {
        var tempNotes = [NotificationModel]()
        let path = "Users/" + self.user!.uid + "/Notifications"
        self.ref?.child(path).observeSingleEvent(of: .value, with: {(snapshot) in
            if snapshot.childrenCount > 0 {
                // get users display name
                self.ref?.child("Users/").observeSingleEvent(of: .value, with: {(snapshot2) in
                    if snapshot2.childrenCount > 0 {
                        // get event display name
                        self.ref?.child("Events/").observeSingleEvent(of: .value, with: {(snapshot3) in
                            if snapshot3.childrenCount > 0 {
                                for u in snapshot.children.allObjects as! [DataSnapshot] {
                                    let eid = u.childSnapshot(forPath: "eventid").value! as! String
                                    let inviterid = u.childSnapshot(forPath: "inviter").value! as! String
                                    let viewed = u.childSnapshot(forPath: "viewed").value! as! Bool
                                    let tstamp = u.childSnapshot(forPath: "timestamp").value! as! NSNumber
                                    let tstring = tstamp.stringValue
                                    // get user display
                                    let display = snapshot2.childSnapshot(forPath: inviterid + "/display").value! as! String
                                   
                                    if snapshot3.childSnapshot(forPath: eid + "/title").exists() {
                                        // get event name
                                        let eventtitle =  snapshot3.childSnapshot(forPath: eid + "/title").value! as! String
                                        
                                        let noti = NotificationModel(inviter1: inviterid, title1: eventtitle, time1: tstring, pic1: Data(), viewed1: viewed, eventid1: eid, inviteDisplay1: display, eventDisplay1: eventtitle)
                                        tempNotes.append(noti)
                                        tempNotes = tempNotes.sorted(by: {(a, b) -> Bool in
                                            if let d1 = a.time {
                                                if let d2 = b.time {
                                                    return d1 > d2
                                                }
                                                return false
                                            }
                                            return false
                                        })
                                    }
                                }
                                self.notifications = tempNotes
                                self.tableView.reloadData()
                                self.refreshControl!.endRefreshing()
                            }
                        })
                    }
                })
            }
        })
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "noti", for: indexPath) as! NotificationsTableViewCell
        
        let note = notifications[indexPath.row]
        
        cell.event.text = note.eventDisplay
        cell.invitedBy.text = note.inviteDisplay! + " has invited you to..."
        
        if !note.viewed! {
            cell.cell.backgroundColor = UIColor(red:0.92, green:0.70, blue:0.70, alpha:1.0)
        }
        else {
            cell.cell.backgroundColor = UIColor.white
        }
        
        // get image
        
        // Create a reference to the file you want to download
        let islandRef = Storage.storage().reference().child("users/" + note.inviter! + ".png")
        // Download in memory with a maximum allowed size of 1MB (1 * 1024 * 1024 bytes)
        islandRef.getData(maxSize: 10 * 1024 * 1024) { data, error in
            if let error = error {
                print(error)
            } else {
                let image = UIImage(data: data!)
                cell.picture.image =  self.resizeImage(image: image!, newWidth: 50.0)
                cell.picture.contentMode = UIView.ContentMode.scaleAspectFill
                cell.picture.clipsToBounds = true
                cell.picture.layer.cornerRadius = 25.0
            }
        }
        return cell
    }

    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let ev = notifications[indexPath.row].eventid
        
        // set notification as read
        let upd = ["viewed": true] as [AnyHashable: Any]
        let path = "Users/" + self.user!.uid + "/Notifications/" + ev!
        self.ref?.child(path).updateChildValues(upd)
        
        // get event display name
        self.ref?.child("Events/" + ev!).observeSingleEvent(of: .value, with: {(snapshot3) in
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
                let islandRef = storageRef.child("events/" + ev! + ".png")
                var image_decode = Data()
                // Download in memory with a maximum allowed size of 1MB (1 * 1024 * 1024 bytes)
                islandRef.getData(maxSize: 10 * 1024 * 1024) { data, error in
                    if let error = error {
                        // Uh-oh, an error occurred!
                    } else {
                        // Data for "images/island.jpg" is returned
                        image_decode = data!
                        self.event = AllEventModel(pub1: pub, pic1: image_decode, loc1: loc, descript1: description, timeCreated1: timestamp, time1: time, title1: title, author1: host, going1: going, viewed1: viewed, invited1: invited, key1: ev!, cat1: cat, inviterDisplay1: "String", eventid1: "", link1: link2)
                        self.performSegue(withIdentifier: "toEvent", sender: nil)
                        tableView.deselectRow(at: indexPath, animated: false)
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
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }
}
