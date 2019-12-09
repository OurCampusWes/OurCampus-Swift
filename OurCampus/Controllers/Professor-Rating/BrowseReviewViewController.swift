//
//  BrowseReviewViewController.swift
//  OurCampus
//
//  Created by Rafael Goldstein on 2/1/19.
//  Copyright © 2019 Rafael Goldstein. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import FirebaseAuth

class BrowseReviewViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
 
    var cl : String = ""
    var rate : String = ""
    var difficulty : String = ""
    var comment : String = ""
    var recommend : String = ""
    var grade : String = ""
    var lecture : String = ""
    var accessible : String = ""
    var userPosted : String = ""
    var returnSpeed : String = ""
    var feedback : String = ""
    var discussion : String = ""
    
    var ref : DatabaseReference?
    var user : User?
    @IBOutlet weak var tbl: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let attrs = [
            NSAttributedString.Key.foregroundColor: UIColor(red:0.77, green:0.12, blue:0.23, alpha:1.0),
            NSAttributedString.Key.font: UIFont(name: "OraqleScript", size: 50)!
        ]
        UINavigationBar.appearance().titleTextAttributes = attrs
        self.navigationItem.title = "OurCampus"
        tbl.separatorColor = UIColor.clear
    }
    
    @IBAction func reportPost(_ sender: Any) {
        let alert = UIAlertController(title: "Report Post?", message: "Flag this post to be reviewed by an administrator. Any post deemed abusive or innapropriate will be removed. Further action may also be taken.", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Report", style: UIAlertAction.Style.default) { (action) in
            if self.user?.email == "support@ourcampus.us.com" {
                let alert = UIAlertController(title: "Unable to Flag", message: "You must be signed into a wesleyan email to report a post", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
            else {
                let ref = Database.database().reference().child("Flagged")
                let flaggedPost = ["FlaggedUser": self.userPosted, "FlaggedBy": self.user?.email, "Comment": self.comment, "Class": self.cl, "Grade": self.grade]
                let key = ref.childByAutoId().key
                ref.child(key!).updateChildValues(flaggedPost as [AnyHashable : Any])
            }
        })
        alert.addAction(UIAlertAction(title: "Go Back", style: UIAlertAction.Style.cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
         let cell = tableView.dequeueReusableCell(withIdentifier: "rateInfo", for: indexPath) as! BrowseReviewTableViewCell
        
        cell.cl.text = cl
        cell.rate.text = rate
        if cell.rate.text == "5" {
            cell.rate.textColor = UIColor(red:0.17, green:0.86, blue:0.11, alpha:1.0)
        }
        else if cell.rate.text == "1" {
            cell.rate.textColor = UIColor(red:0.98, green:0.09, blue:0.14, alpha:1.0)
        }
        cell.difficulty.text = difficulty
        if cell.difficulty.text == "5" {
            cell.difficulty.textColor = UIColor(red:0.98, green:0.09, blue:0.14, alpha:1.0)
        }
        else if cell.difficulty.text == "1" {
            cell.difficulty.textColor = UIColor(red:0.17, green:0.86, blue:0.11, alpha:1.0)
        }
        cell.comment.text = comment
        if grade == "" {
            cell.grade.text = "n/a"
        }
        else {
            cell.grade.text = grade
        }
        
        if recommend == "1" {
            cell.recommend.text = "Yes!"
            cell.recommend.textColor = UIColor(red:0.17, green:0.86, blue:0.11, alpha:1.0)
        }
        else {
            cell.recommend.text = "No"
            cell.recommend.textColor = UIColor(red:0.98, green:0.09, blue:0.14, alpha:1.0)
        }
        
        if lecture == "1" {
            cell.lecture.text = "Ineffective"
            cell.lecture.textColor = UIColor(red:0.98, green:0.09, blue:0.14, alpha:1.0)
        }
        else if lecture == "2" {
             cell.lecture.text = "Fair"
        }
        else if lecture == "3" {
            cell.lecture.text = "Good"
        }
        else if lecture == "4" {
             cell.lecture.text = "Very Good"
        }
        else {
             cell.lecture.text = "Excellent"
             cell.lecture.textColor = UIColor(red:0.17, green:0.86, blue:0.11, alpha:1.0)
        }
        
        if returnSpeed == "1" {
            cell.assignment.text = "Ineffective"
            cell.assignment.textColor = UIColor(red:0.98, green:0.09, blue:0.14, alpha:1.0)
        }
        else if returnSpeed == "2" {
            cell.assignment.text = "Fair"
        }
        else if returnSpeed == "3" {
            cell.assignment.text = "Good"
        }
        else if returnSpeed == "4" {
            cell.assignment.text = "Very Good"
        }
        else {
            cell.assignment.text = "Excellent"
            cell.assignment.textColor = UIColor(red:0.17, green:0.86, blue:0.11, alpha:1.0)
        }
        
        if discussion == "1" {
            cell.discussion.text = "Ineffective"
            cell.discussion.textColor = UIColor(red:0.98, green:0.09, blue:0.14, alpha:1.0)
        }
        else if discussion == "2" {
            cell.discussion.text = "Fair"
        }
        else if discussion == "3" {
            cell.discussion.text = "Good"
        }
        else if discussion == "4" {
            cell.discussion.text = "Very Good"
        }
        else {
            cell.discussion.text = "Excellent"
            cell.discussion.textColor = UIColor(red:0.17, green:0.86, blue:0.11, alpha:1.0)
        }
        
        cell.accessible.text = accessible
        if cell.accessible.text == "No" {
            cell.accessible.textColor = UIColor(red:0.98, green:0.09, blue:0.14, alpha:1.0)
        }
        else {
            cell.accessible.textColor = UIColor(red:0.17, green:0.86, blue:0.11, alpha:1.0)
        }
        cell.feedback.text = feedback
        if cell.feedback.text == "No" {
            cell.feedback.textColor = UIColor(red:0.98, green:0.09, blue:0.14, alpha:1.0)
        }
        else {
            cell.feedback.textColor = UIColor(red:0.17, green:0.86, blue:0.11, alpha:1.0)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 700
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
