//
//  UnsubscribeTableViewController.swift
//  OurCampus
//
//  Created by Rafael Goldstein on 10/29/19.
//  Copyright © 2019 Rafael Goldstein. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import FirebaseAuth

class UnsubscribeTableViewController: UITableViewController {
    
    var classes = [String]()
    
    var user: User!
    var ref : DatabaseReference?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        user = Auth.auth().currentUser
        ref = Database.database().reference()
        getSubs()
        
        self.tableView.separatorStyle = .none
    }

    func getSubs() {
        self.classes.removeAll()
        self.ref?.child("Users/" + user.uid + "/Subscriptions").observeSingleEvent(of: .value, with: {(snapshot) in
            if snapshot.childrenCount > 0 {
                for x in snapshot.children.allObjects as! [DataSnapshot] {
                    let infoObj = x.key as? String
                    self.classes.append(infoObj!)
                    self.tableView.reloadData()
                }
            }
        })
    }


    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return classes.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "class1", for: indexPath) as! UnsubscribeTableViewCell
        
        cell.className.text = "🏫 " + classes[indexPath.row]
        

        return cell
    }

    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let chosenClass = classes[indexPath.row]
        self.tableView.deselectRow(at: indexPath, animated: false)
        let alert = UIAlertController(title: "Are You Sure?", message: "Once you remove the class, you will no longer receive updates", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Remove Sub", style: UIAlertAction.Style.destructive) { (action) in
            let path1 = "Users/" + self.user.uid + "/Subscriptions/" + chosenClass
            let path2 = "Subscriptions/" + chosenClass + "/" + self.user.uid
            self.ref?.child(path1).removeValue()
            self.ref?.child(path2).removeValue()
            self.getSubs()
        })
        
        self.present(alert, animated: true, completion: nil)
        
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }


}
