//
//  ScheduleTableViewController.swift
//  OurCampus
//
//  Created by Rafael Goldstein on 7/15/19.
//  Copyright © 2019 Rafael Goldstein. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage

class ScheduleTableViewController: UITableViewController {
    
    var events_filtered = [AllEventModel]()
    
    var event : AllEventModel!
    
    var user : User?
    
    var ref : DatabaseReference?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let attrs = [
            NSAttributedString.Key.foregroundColor: UIColor(red:0.77, green:0.12, blue:0.23, alpha:1.0),
            NSAttributedString.Key.font: UIFont(name: "OraqleScript", size: 50)!
        ]
        UINavigationBar.appearance().titleTextAttributes = attrs
        self.navigationItem.title = "My Schedule"
        
        user = Auth.auth().currentUser
        ref = Database.database().reference()
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action:  #selector(refreshData), for: .valueChanged)
        self.refreshControl = refreshControl
        
        self.tableView.separatorStyle = .none
        
        refreshData()
    }
    
    
    @objc private func refreshData() {
        self.events_filtered.removeAll()
        self.tableView.reloadData()
        var events = [AllEventModel]()
        
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
                            for e in events {
                                if e.timeCreated == timestamp {
                                    contains = true
                                }
                            }
                            
                            // if it is not added, then append it!
                            if !contains {
                                if !passed {
                                    // get host's display name
                                    if snapshot2.childSnapshot(forPath: host + "/display").exists() {
                                        let h = snapshot2.childSnapshot(forPath: host + "/display").value! as! String
                                        let event1 = AllEventModel(pub1: pub, pic1: Data(), loc1: loc, descript1: description, timeCreated1: timestamp, time1: time, title1: title, author1: host, going1: going, viewed1: viewed, invited1: invited, key1: x.key, cat1: cat, inviterDisplay1: h, eventid1: x.key, link1: link2)
                                        events.append(event1)
                                    }
                                   
                                }
                            }
                        }
                        
                        // only add events user is going to
                        self.events_filtered.removeAll()
                        for i in events {
                            if (i.going?.keys.contains(self.user!.uid))! {
                                self.events_filtered.append(i)
                            }
                            self.events_filtered = self.events_filtered.sorted(by: {(a, b) -> Bool in
                                if let d1 = a.time {
                                    if let d2 = b.time {
                                        return d1 < d2
                                    }
                                    return false
                                }
                                return false
                            })
                        }
                        self.tableView.reloadData()
                        self.refreshControl?.endRefreshing()
                        
                    }
                })
            }
        })
        
        
        
    }
    
    func getDisplayDate(timestamp: String) -> String {
        let dateVar = Date.init(timeIntervalSince1970: TimeInterval(timestamp)!/1000)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E, MMM d, h:mm a"
        
        return dateFormatter.string(from: dateVar)
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
        return events_filtered.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "event", for: indexPath) as! ScheduleTableViewCell
        
        let e = events_filtered[indexPath.row]
        
        cell.title.text = e.title
        let fullDate = getDisplayDate(timestamp: e.time!)
        let splitStr = fullDate.components(separatedBy: ",")
        let monthDay = splitStr[1].components(separatedBy: " ")
        cell.day.text = monthDay[2]
        cell.month.text = monthDay[1]
        let restOfTime = splitStr[0] + "," + splitStr[2]
        
        cell.time.text = "🕒 " + restOfTime
        
        let id = e.author ?? "na"
        
        if e.pub! {
            cell.pub.text = "🔓 Public"
        }
        else {
            cell.pub.text = "🔒 Private"
        }
        
        cell.author.text = "✏️ By " + e.inviterDisplay!
        
        
        
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let ev = events_filtered[indexPath.row]
        // get event display name
        self.ref?.child("Events/" + ev.eventid!).observeSingleEvent(of: .value, with: {(snapshot3) in
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
                let islandRef = storageRef.child("events/" + ev.eventid! + ".png")
                var image_decode = Data()
                // Download in memory with a maximum allowed size of 1MB (1 * 1024 * 1024 bytes)
                islandRef.getData(maxSize: 1 * 1024 * 1024) { data, error in
                    if let error = error {
                        // Uh-oh, an error occurred!
                    } else {
                        // Data for "images/island.jpg" is returned
                        image_decode = data!
                        self.event = AllEventModel(pub1: pub, pic1: image_decode, loc1: loc, descript1: description, timeCreated1: timestamp, time1: time, title1: title, author1: host, going1: going, viewed1: viewed, invited1: invited, key1: snapshot3.key, cat1: cat, inviterDisplay1: "String", eventid1: "", link1: link2)
                        self.performSegue(withIdentifier: "toSingleEvent", sender: nil)
                        tableView.deselectRow(at: indexPath, animated: false)
                    }
                }
            }
        })
        
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 135
    }
}
