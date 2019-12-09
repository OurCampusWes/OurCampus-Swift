//
//  AllEventsTableViewController.swift
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

class AllEventsTableViewController: UITableViewController, UIActionSheetDelegate {
    
    var events = [AllEventModel]()
    
    var filtered_events = [AllEventModel]()
    
    var filter = false
    
    // declare database
    var ref : DatabaseReference?
    
    // firebase account
    var user : User?
    var username = ""
    
    // info for individual event to be tapped
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
    var host = ""
    var pic : Data?
    
    var mili_stamp : Double?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let attrs = [
            NSAttributedString.Key.foregroundColor: UIColor(red:0.77, green:0.12, blue:0.23, alpha:1.0),
            NSAttributedString.Key.font: UIFont(name: "OraqleScript", size: 50)!
        ]
        UINavigationBar.appearance().titleTextAttributes = attrs
        self.navigationItem.title = "All Events"
        
        ref = Database.database().reference()
        user = Auth.auth().currentUser
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action:  #selector(refreshData), for: .valueChanged)
        self.refreshControl = refreshControl
        
        // filter
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Filter", style: .done, target: self, action: #selector(filterEvents))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(addTapped))
        
        self.tableView.separatorStyle = .none
        
        refreshData()
        
        // notifications
        Messaging.messaging().subscribe(toTopic: "general") { error in
            print("Subscribed to general topic")
        }
        
        // get firebase token refresh
        self.ref?.child("Users/" + user!.uid).observeSingleEvent(of: .value, with: {(snapshot) in
            if snapshot.childrenCount > 0 {
//                self.getToken()
            }
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
    
    @objc func addTapped() {
        self.performSegue(withIdentifier: "toCreate", sender: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        getTabBarBadge()
        self.ref?.child("Users/" + user!.uid).observeSingleEvent(of: .value, with: {(snapshot) in
        if snapshot.childrenCount > 0 {
           let infoObj = snapshot.value as? [String:AnyObject]
           let alt = infoObj?["user"] as! String
           let u = infoObj?["display"] as? String ?? alt
           if u.contains("@") {
               self.performSegue(withIdentifier: "toAddInfo", sender: nil)
           }
            }
        else {
            self.performSegue(withIdentifier: "toAddInfo", sender: nil)
            }
        })
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
    
    @objc func filterEvents() {
        // first need to give menu to choose which category
        let alert = UIAlertController(title: nil, message: "Please Select a Category to Filter by", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Athletics", style: .default , handler:{ (UIAlertAction)in
            self.filtered_events = self.events.filter { $0.cat == "Athletics" }
            self.filter = true
            self.navigationItem.title = "Athletics"
            self.tableView.reloadData()
        }))
        
        alert.addAction(UIAlertAction(title: "Activism", style: .default , handler:{ (UIAlertAction)in
            self.filtered_events = self.events.filter { $0.cat == "Activism" }
            self.filter = true
            self.navigationItem.title = "Activism"
            self.tableView.reloadData()
        }))
        
        alert.addAction(UIAlertAction(title: "Education", style: .default , handler:{ (UIAlertAction)in
            self.filtered_events = self.events.filter { $0.cat == "Education" }
            self.filter = true
            self.navigationItem.title = "Education"
            self.tableView.reloadData()
        }))
        
        alert.addAction(UIAlertAction(title: "Shows", style: .default , handler:{ (UIAlertAction)in
            self.filtered_events = self.events.filter { $0.cat == "Shows" }
            self.filter = true
            self.navigationItem.title = "Shows"
            self.tableView.reloadData()
        }))
        
        alert.addAction(UIAlertAction(title: "Social", style: .default , handler:{ (UIAlertAction)in
            self.filtered_events = self.events.filter { $0.cat == "Social" }
            self.filter = true
            self.navigationItem.title = "Social"
            self.tableView.reloadData()
        }))
        
        alert.addAction(UIAlertAction(title: "Rides", style: .default , handler:{ (UIAlertAction)in
            self.filtered_events = self.events.filter { $0.cat == "Rides" }
            self.filter = true
            self.navigationItem.title = "Rides"
            self.tableView.reloadData()
        }))
        
        alert.addAction(UIAlertAction(title: "All", style: .default , handler:{ (UIAlertAction)in
            self.filter = false
            self.navigationItem.title = "All Events"
            self.tableView.reloadData()
        }))
        
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc private func refreshData() {
        events.removeAll()
        self.tableView.reloadData()
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
                            
                            var gotInv = false
                            for user in invited {
                                if user.key == self.user?.uid {
                                    gotInv = true
                                }
                            }
                            
                            if pub || gotInv {
                                
                                
                                
                            
                            
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
                            
                            // if it is not added, then append it!
                            if !contains {
                                if !passed {
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
                            if let d1 = a.time {
                                if let d2 = b.time {
                                    return d1 < d2
                                }
                                return false
                            }
                            return false
                        })
                        self.events = tempEvents
                        self.tableView.reloadData()
                        self.refreshControl?.endRefreshing()
                        
                    }
                })
            }
        })
    }
    
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is SingleEventViewController {
            let vc = segue.destination as? SingleEventViewController
            vc?.event = event
            vc?.event_id = event?.eventid
        }
    }
    
    func getDisplayDate(timestamp: String) -> String {
        let dateVar = Date.init(timeIntervalSince1970: TimeInterval(timestamp)!/1000)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E, MMM d, h:mm a"
        
        return dateFormatter.string(from: dateVar)
    }
    
    
    // function based on user id to get user's display name
    func getUser(id: String) {
        self.ref?.child("Users/" + id).observeSingleEvent(of: .value, with: {(snapshot) in
            if snapshot.childrenCount > 0 {
                let infoObj = snapshot.value as? [String:AnyObject]
                let u = infoObj?["display"] as! String
                self.username = u
            }
        })
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if filter {
            return filtered_events.count
        }
        return events.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "event", for: indexPath) as! AllEventsTableViewCell
        
        var ev : AllEventModel?
        if filter {
            ev = filtered_events[indexPath.row]
        }
            
        else {
            ev = events[indexPath.row]
        }
        
        let id = ev!.author ?? "na"
        
        let p = ev!.pub as! Bool
        let inv = ev!.invited ?? [:]
        cell.author.text = "✏️ By " + ev!.inviterDisplay!
        
        let c = ev!.going?.count ?? 0
        
        if c == 1 {
            cell.going.text = "✈️ " + String(c)
        }
        else {
            cell.going.text = "✈️ " + String(c)
        }
        
        cell.title.text = ev!.title
        
        if ev!.pub! {
            cell.pub.text = "🔓 Public"
        }
        else {
            cell.pub.text = "🔒 Private"
        }
        
        let fullDate = getDisplayDate(timestamp: ev!.time!)
        let splitStr = fullDate.components(separatedBy: ",")
        let monthDay = splitStr[1].components(separatedBy: " ")
        cell.day.text = monthDay[2]
        cell.month.text = monthDay[1]
        let restOfTime = splitStr[0] + "," + splitStr[2]
        
        cell.time.text = "🕒 " + restOfTime
        
        if ev?.cat == "Athletics" {
            cell.cat.text = "🏆 Athletics"
        }
        else if ev?.cat == "Education" {
            cell.cat.text = "🎒 Education"
        }
        else if ev?.cat == "Shows" {
            cell.cat.text = "🎭 Shows"
        }
        else if ev?.cat == "Social" {
            cell.cat.text = "🥳 Social"
        }
        else if ev?.cat == "Rides" {
            cell.cat.text = "🏎️ Rides"
        }
            
        else if ev?.cat == "Activism"{
            cell.cat.text = "🗣 Activism"
        }
        
        // other
        else {
            cell.cat.text = "🌀 Other"
        }
        
        return cell
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if filter {
            event = filtered_events[indexPath.row]
        }
        else {
            event = events[indexPath.row]
        }
        
        self.performSegue(withIdentifier: "toSingleEvent", sender: nil)
        tableView.deselectRow(at: indexPath, animated: false)
        
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 175
    }
    
}
