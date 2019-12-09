//
//  SubscribeViewController.swift
//  OurCampus
//
//  Created by Rafael Goldstein on 8/8/19.
//  Copyright © 2019 Rafael Goldstein. All rights reserved.
//

import UIKit
import MessageUI
import Firebase
import FirebaseAuth

class SubscribeViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource {

    
    @IBOutlet weak var autoTable: UITableView!
    @IBOutlet weak var classInput: UITextField!
    
    var autoCompletionPossibilities = [String]()
    var allClasses = [String]()
    var autoCompleteCharacterCount = 0
    var timer = Timer()
    
    var user: User!
    var ref : DatabaseReference?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let attrs = [
            NSAttributedString.Key.foregroundColor: UIColor(red:0.77, green:0.12, blue:0.23, alpha:1.0),
            NSAttributedString.Key.font: UIFont(name: "OraqleScript", size: 50)!
        ]
        UINavigationBar.appearance().titleTextAttributes = attrs
        self.navigationItem.title = "Subscribe"
        
        user = Auth.auth().currentUser
        ref = Database.database().reference()
        
        getClasses()
        
        classInput.delegate = self

        // Do any additional setup after loading the view.
        autoTable.isHidden = true
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Unsubscribe", style: .plain, target: self, action: #selector(toUnsubscribe))
    }
    
    @objc func toUnsubscribe() {
        self.performSegue(withIdentifier: "toUnsub", sender: nil)
    }
    
    func getClasses() {
        self.ref?.child("Spring20").observeSingleEvent(of: .value, with: {(snapshot) in
            if snapshot.childrenCount > 0 {
                for x in snapshot.children.allObjects as! [DataSnapshot] {
                    let infoObj = x.key as? String
                    self.allClasses.append(infoObj!)
                }
            }
        })
    }
    
    func subscribeDatabase(class1: String) {
        let key = (self.ref?.childByAutoId().key)!
        let classSubscribe = [class1: "nil"]
        let username = user.uid
        let userWrite = [username: "nil"]
        self.ref?.child("Subscriptions/" + class1).updateChildValues(userWrite as [AnyHashable: Any])
        
        self.ref?.child("Users/" + username + "/Subscriptions").updateChildValues(classSubscribe as [AnyHashable: Any])
        
        let alert = UIAlertController(title: "Subscribed!", message: "You will now receive push notifications when a seat opens up in your chosen course", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if allClasses.contains(classInput.text ?? "") {
            subscribeDatabase(class1: classInput.text ?? "")
        }
        else {
            let alert = UIAlertController(title: "Unable to Subscribe", message: "Please input a valid course number", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        autoTable.isHidden = false
        var substring = classInput.text
        substring = formatSubstring(subString: substring ?? "")
        searchAutocompleteEntriesWithSubstring(substring: substring!)
        return true
    }
    
    func formatSubstring(subString: String) -> String {
        let formatted = String(subString.dropLast(autoCompleteCharacterCount)).uppercased() //5
        return formatted
    }
    
    func searchAutocompleteEntriesWithSubstring(substring: String) {
        autoCompletionPossibilities.removeAll()
        for c in allClasses {
            if c.hasPrefix(substring) {
                    if !autoCompletionPossibilities.contains(c) {
                        autoCompletionPossibilities.append(c)
                    }
                }
            }
        autoTable.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return autoCompletionPossibilities.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "optionsCell", for: indexPath) as! AutoCorrectTableViewCell
        cell.option.text = autoCompletionPossibilities[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.classInput.text = autoCompletionPossibilities[indexPath.row]
        autoTable.isHidden = true
        if allClasses.contains(classInput.text ?? "") {
            self.subscribeDatabase(class1: self.classInput.text ?? "")
            self.classInput.text = ""
        }
    }
    
   

}
