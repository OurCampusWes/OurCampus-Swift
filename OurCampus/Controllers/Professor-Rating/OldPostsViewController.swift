//
//  OldPostsViewController.swift
//  OurCampus
//
//  Created by Rafael Goldstein on 12/27/18.
//  Copyright © 2018 Rafael Goldstein. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase

class OldPostsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var user = ""
    @IBOutlet weak var userLabel: UILabel!
    var ref: DatabaseReference?
    
    @IBOutlet weak var tblPosts: UITableView!
    var postsList = [OldPostModel]()
    
    let network = NetworkManager.sharedInstance

    override func viewDidLoad() {
        let attrs = [
            NSAttributedString.Key.foregroundColor: UIColor(red:0.77, green:0.12, blue:0.23, alpha:1.0),
            NSAttributedString.Key.font: UIFont(name: "OraqleScript", size: 50)!
        ]
        UINavigationBar.appearance().titleTextAttributes = attrs
        self.navigationItem.title = "OurCampus"
        super.viewDidLoad()
        if user != "" {
            let username = user.components(separatedBy: "@")
            userLabel.text = username[0]
        }
        network.reachability.whenUnreachable = { reachability in
            self.showOfflinePage()
        }
        tblPosts.isScrollEnabled = true
        getPosts()
        tblPosts.isHidden = true
    }
    
    private func showOfflinePage() -> Void {
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "NetworkUnavailable", sender: self)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return postsList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "postCell", for: indexPath) as! OldPostsTableViewCell
        let post: OldPostModel
        if indexPath.row == 0 {
            tblPosts.isHidden = false
        }
        
        post = postsList[indexPath.row]
        
        cell.class1.text = post.className
        let date = post.date?.components(separatedBy: ",")
        cell.date.text = date?[0]
        cell.rate.text = post.rate
        cell.diff.text = post.difficulty
        cell.comment.text = post.comment
        if post.grade == "" {
            cell.grade.text = "n/a"
        }
        else {
            cell.grade.text = post.grade
        }
        cell.prof.text = post.prof1
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let p1: OldPostModel
        p1 = postsList[indexPath.row]
        let num = p1.comment?.count
        return CGFloat(400 + (CGFloat(num!) / (UIScreen.main.bounds.width - 15)))
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let alert = UIAlertController(title: "Delete Review?", message: "Once your review is deleted, it is gone!", preferredStyle: UIAlertController.Style.alert)
        let actDelete = UIAlertAction(title: "Delete", style: UIAlertAction.Style.destructive) { (action) in
            let p1 = self.postsList[indexPath.row]
            let prof = p1.prof1
            let date = p1.date
            
            Database.database().reference().child("Ratings/" + prof!).observeSingleEvent(of: .value, with: {(snapshot) in
            if snapshot.childrenCount > 0 {
                for x in snapshot.children.allObjects as! [DataSnapshot] {
                    let infoObj = x.value as? [String: AnyObject]
                    let u = infoObj?["user"]
                    let d = infoObj?["timestamp"]
                    if u as! String? == self.user && d as! String? == date {
                        let key = x.key
                        let username = self.user.components(separatedBy: "@")
                        let user1 = username[0]
                        let url = "Deleted/" + user1 + "/" + prof! + "/" + key + "/"
                        Database.database().reference().child(url).updateChildValues(x.value as! [AnyHashable : Any])
                       Database.database().reference().child("Ratings/" + prof! + "/" + x.key).removeValue()
                        }
                    }
                }
            }
        )
        self.tblPosts.isHidden = true
        let progressHUD = ProgressHUD(text: "Deleting")
        self.view.addSubview(progressHUD)
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3), execute: {
            self.postsList.removeAll()
            self.getPosts()
            self.tblPosts.reloadData()
            progressHUD.isHidden = true
            self.tblPosts.isHidden = false
            })
        }
        
        let actReturn = UIAlertAction(title: "Go Back", style: UIAlertAction.Style.default, handler: nil)
        alert.addAction(actReturn)
        alert.addAction(actDelete)
        self.present(alert, animated: true, completion: nil)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func getPosts() {
        ref = Database.database().reference()
        
        ref?.child("Ratings").observe(.value, with: {(snapshot) in
            if snapshot.childrenCount > 0 {
                for prof in snapshot.children.allObjects as! [DataSnapshot] {
                    let p1 = prof.key as String
                    self.ref =  Database.database().reference().child("Ratings" + "/" + p1 + "/")
                    self.ref?.observe(.value, with: {(snapshot2) in
                        if snapshot2.childrenCount > 0 {
                            for x in snapshot2.children.allObjects as! [DataSnapshot] {
                                let infoObj = x.value as? [String: AnyObject]
                                let u = infoObj?["user"]
                                if u as! String? == self.user {
                                    let d = infoObj?["timestamp"] as! String?
                                    let c = infoObj?["class"] as! String?
                                    let r = infoObj?["rate"] as! String?
                                    let dr = infoObj?["difficulty"] as! String?
                                    let com = infoObj?["comments"] as! String?
                                    let grade = infoObj?["grade"] as! String?
                                    let post = OldPostModel(rate1: r, difficulty1: dr, com1: com, className1: c, grade1: grade, date1: d, prof: p1)
                                    self.postsList.append(post)
                                }
                                // sort by most recent
                                self.postsList = self.postsList.sorted(by: { (a, b) -> Bool in
                                    if let x1 = a.date {
                                        if let x2 = b.date {
                                            let dateformatter = DateFormatter()
                                            dateformatter.dateFormat = "MM/dd/yy, h:mm a"
                                            let a = dateformatter.date(from: x1)!
                                            let b = dateformatter.date(from: x2)!
                                            return a > b
                                        }
                                        return false
                                    }
                                    return false
                                })
                                self.tblPosts.reloadData()
                            }
                        }
                        
                    })
                }
            }
            
        })
    }
}
