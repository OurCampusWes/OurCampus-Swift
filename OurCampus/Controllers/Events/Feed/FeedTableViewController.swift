//
//  FeedTableViewController.swift
//  OurCampus
//
//  Created by Rafael Goldstein on 7/18/19.
//  Copyright © 2019 Rafael Goldstein. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage

class FeedTableViewController: UITableViewController {
    
    var feed = [FeedModel]()
    
    var event : AllEventModel?
    
    var ref : DatabaseReference?
    var user : User?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let attrs = [
                   NSAttributedString.Key.foregroundColor: UIColor(red:0.77, green:0.12, blue:0.23, alpha:1.0),
                   NSAttributedString.Key.font: UIFont(name: "OraqleScript", size: 50)!
               ]
        UINavigationBar.appearance().titleTextAttributes = attrs
        self.navigationItem.title = "Feed"
        
        
        ref = Database.database().reference()
        user = Auth.auth().currentUser
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action:  #selector(refreshData), for: .valueChanged)
        self.refreshControl = refreshControl
        
        self.tableView.separatorStyle = .none
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
    
    @IBAction func toAll(_ sender: Any) {
        self.performSegue(withIdentifier: "toAll", sender: nil)
    }
    
    
    @objc private func refreshData() {
        self.feed.removeAll()
        self.tableView.reloadData()
        var tempFeed = [FeedModel]()
        self.ref?.child("Feed").observeSingleEvent(of: .value, with: {(snapshot) in
            if snapshot.childrenCount > 0 {
                self.ref?.child("Users").observeSingleEvent(of: .value, with: { (snapshot2) in
                    self.ref?.child("Events").observeSingleEvent(of: .value, with: { (snapshot3) in
                        for e in snapshot.children.allObjects as! [DataSnapshot] {
                            for p in e.children {
                                let pSnap = p as? DataSnapshot
                                let eid = pSnap?.childSnapshot(forPath: "eventid").value! as! String
                                let tstamp = pSnap?.childSnapshot(forPath: "timestamp").value! as! NSNumber
                                let tstring = tstamp.stringValue
                                let uid =  pSnap?.childSnapshot(forPath: "userid").value! as! String
                                let display = snapshot2.childSnapshot(forPath: uid + "/display").value! as! String
                                let event = snapshot3.childSnapshot(forPath: eid + "/title").value! as! String
                                let eventuser = snapshot3.childSnapshot(forPath: eid + "/host").value! as! String
                                var creator = false
                                if eventuser == uid {
                                    creator = true
                                }
                                tempFeed.append(FeedModel(user1: uid, display1: display, event1: event, pic1: Data(), date1: tstring, eventid1: eid, created1: creator))
                                
                            }
                        }
                        tempFeed = tempFeed.sorted(by: {(a, b) -> Bool in
                            if let d1 = a.date {
                                if let d2 = b.date {
                                    return d1 > d2
                                }
                                return false
                            }
                            return false
                        })
                        self.feed = tempFeed
                        self.tableView.reloadData()
                        self.refreshControl!.endRefreshing()
                        
                    })
                })
            }
        })
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "feed", for: indexPath) as! FeedTableViewCell
        
        let c = feed[indexPath.row]
        
        cell.event.text = c.event
        
        if c.created {
            cell.user.text = c.display! + " created the event.."
        }
        else {
            cell.user.text = c.display! + " is going to.."
        }
        
        
        // Create a reference to the file you want to download
        let islandRef = Storage.storage().reference().child("users/" + c.user! + ".png")
        // Download in memory with a maximum allowed size of 1MB (1 * 1024 * 1024 bytes)
        islandRef.getData(maxSize: 10 * 1024 * 1024) { data, error in
            if let error = error {
                print(error)
            } else {
                let image_decode = UIImage(data: data!)
                cell.proPic.image =  self.resizeImage(image: image_decode!, newWidth: 55.0)
                cell.proPic.contentMode = UIView.ContentMode.scaleAspectFill
                cell.proPic.clipsToBounds = true
                cell.proPic.layer.cornerRadius = 25.0
            }
        }
        
        
        return cell
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
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return feed.count
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let ev = feed[indexPath.row].eventid
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
                islandRef.getData(maxSize: 1 * 1024 * 1024) { data, error in
                    if let error = error {
                        // Uh-oh, an error occurred!
                    } else {
                        // Data for "images/island.jpg" is returned
                        image_decode = data!
                        self.event = AllEventModel(pub1: pub, pic1: image_decode, loc1: loc, descript1: description, timeCreated1: timestamp, time1: time, title1: title, author1: host, going1: going, viewed1: viewed, invited1: invited, key1: ev!, cat1: cat, inviterDisplay1: "", eventid1: "", link1: link2)
                        self.performSegue(withIdentifier: "toSingle", sender: nil)
                        tableView.deselectRow(at: indexPath, animated: false)
                    }
                }
            }
        })
    }
    @IBAction func createTapped(_ sender: Any) {
        self.performSegue(withIdentifier: "toCreate", sender: nil)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 105
    }
    
  
}
