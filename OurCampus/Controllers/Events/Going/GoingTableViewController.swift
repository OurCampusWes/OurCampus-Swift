//
//  GoingTableViewController.swift
//  OurCampus
//
//  Created by Rafael Goldstein on 8/23/19.
//  Copyright © 2019 Rafael Goldstein. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase

class GoingTableViewController: UITableViewController {
    
    var going = [String]()
    // declare database
    var ref : DatabaseReference?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        
    }


    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return going.count
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(integerLiteral: 60)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "going", for: indexPath) as! GoingTableViewCell

        let id = going[indexPath.row]
        
        self.ref?.child("Users/" + id).observeSingleEvent(of: .value, with: {(snapshot) in
            if snapshot.childrenCount > 0 {
                let infoObj = snapshot.value as? [String:AnyObject]
                var user = infoObj?["user"] as! String
                var display = infoObj?["display"]
                print(display)
                if display == nil {
                    var dis = user
                    let arr = user.components(separatedBy: "@")
                    user = arr[0]
                    
                    let name = dis + " (" + user + ")"
                    cell.name.text = name
                }
                else {
                    let dis2 = display as!String
                    let arr = user.components(separatedBy: "@")
                    user = arr[0]
                
                    let name = dis2 + " (" + user + ")"
                    cell.name.text = name
                }
            }
        })
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

}
