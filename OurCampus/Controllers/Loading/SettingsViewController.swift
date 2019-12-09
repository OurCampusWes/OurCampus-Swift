//
//  SettingsViewController.swift
//  OurCampus
//
//  Created by Rafael Goldstein on 8/12/19.
//  Copyright © 2019 Rafael Goldstein. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage

class SettingsViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var displayName: UITextField!
    @IBOutlet weak var proPicButton: UIButton!
    
    var name : String?
    
    var userid : String?
    var ref : DatabaseReference?
    
    @IBOutlet weak var incogSwitch: UISwitch!
    
    @IBOutlet weak var incogLabel: UILabel!
    
    var switchChanged = false
    var value : Bool?
    
    var imageData : Data?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let attrs = [
            NSAttributedString.Key.foregroundColor: UIColor(red:0.77, green:0.12, blue:0.23, alpha:1.0),
            NSAttributedString.Key.font: UIFont(name: "OraqleScript", size: 50)!
        ]
        UINavigationBar.appearance().titleTextAttributes = attrs
        self.navigationItem.title = "Settings"
        
        userid = Auth.auth().currentUser?.uid
        ref = Database.database().reference()

        displayName.addTarget(self, action: #selector(textFieldDidChange), for: UIControl.Event.editingChanged)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(addTapped))
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
        incogSwitch.addTarget(self, action: #selector(switchChange), for: UIControl.Event.valueChanged)
        
        let tapped1 = UITapGestureRecognizer(target: self, action: #selector(incogHelp))
        incogLabel.isUserInteractionEnabled = true
        incogLabel.addGestureRecognizer(tapped1)
        
        getIncogSwitchVal()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is SignInViewController {
            let vc = segue.destination as! SignInViewController
            vc.navigationController?.isToolbarHidden = true
            vc.navigationController?.isNavigationBarHidden = true
        }
    }
    
    func getIncogSwitchVal() {
        self.ref?.child("Users/" + userid!).observeSingleEvent(of: .value, with: {(snapshot) in
            if snapshot.childrenCount > 0 {
                let infoObj = snapshot.value as? [String:AnyObject]
                let val = infoObj?["incognito"] as! Bool
                self.incogSwitch.isOn = val
            }
        })
    }
    
    @objc func incogHelp() {
        let alert = UIAlertController(title: "Incognito Mode", message: "When turned on, your activity will not show up in the feed", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc func switchChange() {
        value = incogSwitch.isOn
        switchChanged = true
    }
    
    @IBAction func picTapped(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.allowsEditing = true
        picker.delegate = self
        present(picker, animated: true)
    }
    
    //Calls this function when the tap is recognized.
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    @objc func textFieldDidChange() {
        name = displayName.text
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.editedImage] as? UIImage else { return }
        
        dismiss(animated: true)
        
        if let imageData2 = image.jpeg(.lowest) {
            imageData = imageData2
        }
    }
    
    //  save changes to profile
    @objc func addTapped() {
        if imageData != nil {
            let storage = Storage.storage()
            
            // Create a root reference
            let storageRef = storage.reference()
            
            // Create a reference to the file you want to upload
            let riversRef = storageRef.child("users/" + userid! + ".png")
            
            let im = UIImage(data: imageData!)
            
            if let imageData2 = im?.jpeg(.lowest) {
                // Upload the file to the path "images/rivers.jpg"
                let uploadTask = riversRef.putData(imageData!, metadata: nil) { (metadata, error) in
                    guard let metadata = metadata else {
                        // Uh-oh, an error occurred!
                        return
                    }
                    // Metadata contains file metadata such as size, content-type.
                    let size = metadata.size
                    // You can also access to download URL after upload.
                    riversRef.downloadURL { (url, error) in
                        guard let downloadURL = url else {
                            // Uh-oh, an error occurred!
                            return
                        }
                    }
                }
            }
        }
        
        if name != nil {
            if name!.count > 15 && name!.count < 3 {
                // give user alert they need to fill out all info
                let alert = UIAlertController(title: "Wait", message: "Limit your display name between 3 and 15 characters", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
            else {
                let info = ["display": name] as [AnyHashable:Any]
                
                ref?.child("Users/" + userid!).updateChildValues(info)
            }
        }
        
        if switchChanged {
            let inc = ["incognito": value] as [AnyHashable:Any]
            
            ref?.child("Users/" + userid!).updateChildValues(inc)
        }
        
        var goback = true
        
        if name == nil && imageData == nil && !switchChanged {
            let alert = UIAlertController(title: "Unable to change info", message: "Nothing was updated", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            goback = false
        }
        
        if goback {
            navigationController?.popViewController(animated: true)
        }
    }
    
    @IBAction func logOut(_ sender: Any) {
        do {
            try Auth.auth().signOut()
            self.performSegue(withIdentifier: "toSignIn", sender: nil)
        }
        catch {
            // already signed out
            self.performSegue(withIdentifier: "toSignIn", sender: nil)
        }
    }
    
    func deletePosts(email: String) {
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "MM:dd:yyyy"
        let timestamp = formatter.string(from: date)
        let refOG = Database.database().reference()
        
        refOG.child("Ratings").observe(.value, with: {(snapshot) in
            if snapshot.childrenCount > 0 {
                for prof in snapshot.children.allObjects as! [DataSnapshot] {
                    let p1 = prof.key as String
                    let ref =  Database.database().reference().child("Ratings" + "/" + p1 + "/")
                    ref.observe(.value, with: {(snapshot2) in
                        if snapshot2.childrenCount > 0 {
                            for x in snapshot2.children.allObjects as! [DataSnapshot] {
                                let infoObj = x.value as? [String: AnyObject]
                                let u = infoObj?["user"]
                                if u as! String? == email {
                                    let d = infoObj?["timestamp"] as! String?
                                    let c = infoObj?["class"] as! String?
                                    let r = infoObj?["rate"] as! String?
                                    let dr = infoObj?["difficulty"] as! String?
                                    let com = infoObj?["comments"] as! String?
                                    let grade = infoObj?["grade"] as! String?
                                    
                                    let classUpdate = ["professor": p1,
                                                       "class": c,
                                                       "rate": r,
                                                       "difficulty": dr,
                                                       "comments": com,
                                                       "grade": grade,
                                                       "user": email,
                                                       "timestamp": d]
                                    let key = ref.child("DeletedUsers/").childByAutoId().key
                                    let username = email.components(separatedBy: "@")
                                    let emailConcat = username[0]
                                    var path = "DeletedUsers/" + emailConcat + "/"
                                    path = path + timestamp + "/" + key!
                                    refOG.child(path).updateChildValues(classUpdate as [AnyHashable : Any])
                                    refOG.child("Ratings/" + p1 + "/" + x.key).removeValue()
                                }
                                
                            }
                        }
                        
                    })
                }
            }
            
        })
    }
    
    func deleteEvents() {
        ref?.child("Events/").observeSingleEvent(of: .value, with: {(snapshot) in
            if snapshot.childrenCount > 0 {
                for e in snapshot.children.allObjects as! [DataSnapshot] {
                    let infoObj = e.value as? [String: AnyObject]
                    let u = infoObj?["user"] as! String
                    if u == self.userid {
                        self.ref!.child("Events/" + e.key).removeValue()
                    }
                }
            }
        })
    }

    @IBAction func deleteAccount(_ sender: Any) {
        let alert = UIAlertController(title: "Are You Sure?", message: "Once you delete your account, there is no way to recover your posts", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Delete Account", style: UIAlertAction.Style.destructive) { (action) in
           
                self.deletePosts(email: (Auth.auth().currentUser?.email)!)
                self.deleteEvents()
                
                Auth.auth().currentUser?.delete(completion: nil)
                do {
                    try Auth.auth().signOut()
                    self.performSegue(withIdentifier: "toSignIn", sender: nil)
                }
                catch {
                    self.performSegue(withIdentifier: "toSignIn", sender: nil)
                }
            
        })
        self.present(alert, animated: true, completion: nil)
    }
    

}
