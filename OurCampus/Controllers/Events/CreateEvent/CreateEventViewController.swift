//
//  CreateEventViewController.swift
//  OurCampus
//
//  Created by Rafael Goldstein on 7/10/19.
//  Copyright © 2019 Rafael Goldstein. All rights reserved.
//

import UIKit
import Photos
import UserNotifications
import Firebase
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import FirebaseMessaging

class CreateEventViewController: UIViewController, UITextViewDelegate, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    @IBOutlet weak var doneDate: UIButton!
    @IBOutlet weak var loc: UITextField!
    @IBOutlet weak var title1: UITextField!
    @IBOutlet weak var time: UITextField!
    let datePicker = UIDatePicker()
    @IBOutlet weak var descript: UITextView!
    @IBOutlet weak var publicButton: UIButton!
    @IBOutlet weak var privateButton: UIButton!
    var publicEvent = true
    var currentImage: UIImage!
    @IBOutlet weak var inviteButton: UIButton!
    @IBOutlet weak var photoButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var cat: UITextField!
    
    var user : User?
    var users = [AddFriendModel]()
    
    // declare database
    var ref : DatabaseReference?
    
    var invited = [String:String]()
    var post_date = Date()
    
    // for the editing functiion
    var tit : String?
    var lo : String?
    var ti : String?
    var desc : String?
    var going : [String:String]?
    var host : String?
    var viewed : [String : String]?
    var key : String?
    var final_stamp : Double?
    var edit = false
    var category : String?
    var link1 : String?
    
    var mili_stamp = ""
    
    @IBOutlet weak var datepick: UIDatePicker!
    
    var imageData : Data?
    // Get a reference to the storage service using the default Firebase App
    let storage = Storage.storage()
    
    var pic = Data()
    
    @IBOutlet weak var categoryPicker: UIPickerView!
    
    var cats = ["-", "Activism", "Athletics", "Education", "Shows", "Social", "Rides", "Other"]
    
    @IBOutlet weak var addLink: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if edit {
            cat.text = category
            title1.text = tit
            loc.text = lo
            time.text = ti
            descript.text = desc
            imageData = pic
            
            let dateVar = Date.init(timeIntervalSince1970: TimeInterval(mili_stamp)!/1000)
            
            datepick.date = dateVar
            post_date = dateVar
            
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Update", style: .done, target: self, action: #selector(updateTapped))
            
            
            deleteButton.isHidden = false
        }
        else {
            descript.text = "Description"
            descript.textColor = UIColor.lightGray
            deleteButton.isHidden = true
        }
        
        // set up regular buttons (starts with public event)
        privateButton.layer.borderColor = UIColor(red:0.84, green:0.84, blue:0.84, alpha:1.0).cgColor
        privateButton.layer.backgroundColor = UIColor(red:0.84, green:0.84, blue:0.84, alpha:1.0).cgColor
        publicButton.layer.borderColor = UIColor(red:0.77, green:0.12, blue:0.23, alpha:1.0).cgColor
        publicButton.layer.backgroundColor = UIColor(red:0.77, green:0.12, blue:0.23, alpha:1.0).cgColor
        
        
        descript.delegate = self
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
        setTextViews()
        
        time.delegate = self
        time.tag = 0
        
        cat.delegate = self
        cat.tag = 1
        
        ref = Database.database().reference()
        user = Auth.auth().currentUser
        
        datepick.isHidden = true
        doneDate.isHidden = true
        categoryPicker.isHidden = true
        categoryPicker.delegate = self
        
        datepick.datePickerMode = .dateAndTime
        time.addTarget(self, action: #selector(dateAndTime), for: .touchDown)
        cat.addTarget(self, action: #selector(categories), for: .touchDown)
        getUsers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if invited.count > 0 {
            inviteButton.setTitle("Friends Invited ✅", for: .normal)
            inviteButton.setTitleColor(UIColor.green, for: .normal)
        }
        
        if link1 != nil {
            if link1 != "placehold" {
                addLink.setTitle("Link Added ✅", for: .normal)
                addLink.setTitleColor(UIColor.green, for: .normal)
            }
        }
    }
    
    @IBAction func addLinkTapped(_ sender: Any) {
        performSegue(withIdentifier: "toLink", sender: nil)
    }
    
    @IBAction func deleteTapped(_ sender: Any) {
        
        let alert = UIAlertController(title: "Are You Sure?", message: "Once you delete your event, there is no way to recover the info", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Delete Event", style: UIAlertAction.Style.destructive) { (action) in
           
            let refDelete = self.ref!.child("Events/" + self.key!)
                
                refDelete.removeValue { error, _ in
                    print(error)
                }
                
                // Create a root reference
            let storageRef = self.storage.reference()
                
                // Create a reference to the file you want to upload
                let riversRef = storageRef.child("events/" + self.key! + ".png")
                
                //Removes image from storage
                riversRef.delete { error in
                    if let error = error {
                        print(error)
                    } else {
                        // File deleted successfully
                    }
                }
                
                // but need to save rest of info elsewhere
                let myTimeStamp = self.post_date.timeIntervalSince1970 as! Double
                let st = myTimeStamp * 1000
                let post = ["eventid": self.key, "description": self.descript.text, "going": self.going, "host": self.user?.uid, "invited": self.invited, "location": self.loc.text ?? "Unknown", "public": self.publicEvent, "eventtime": st, "title": self.title1.text ?? "Unknown", "timeposted": self.final_stamp, "viewed": self.viewed, "deletedtime": [".sv": "timestamp"], "category": self.cat.text] as [AnyHashable : Any]
                self.ref!.child("DeletedEvents/" + self.key!).updateChildValues(post)
                
                self.navigationController?.popToRootViewController(animated: true)
            
        })
        
        self.present(alert, animated: true, completion: nil)
        
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return cats.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return cats[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        cat.text = cats[row]
    }
    
    @objc func categories() {
        self.view.endEditing(true)
        datepick.isHidden = true
        categoryPicker.isHidden = false
        inviteButton.isHidden = true
        descript.isHidden = true
        photoButton.isHidden = true
        publicButton.isHidden = true
        privateButton.isHidden = true
        doneDate.isHidden = false
        addLink.isHidden = true
        
    }
    
    @objc func updateTapped() {
        // leave no empty fields
        if title1.text == "" || loc.text == "" || time.text == "" || descript.text == "Description" || cat.text == "-" || cat.text == "" {
            let alert = UIAlertController(title: "Wait!", message: "Please fill out all the criteria for the event", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
            
        else if imageData == nil {
            let alert = UIAlertController(title: "Wait!", message: "Please add a photo", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
            
        else if descript.text.count > 160 {
            let alert = UIAlertController(title: "Wait!", message: "Please limit your description to 160 characters", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
            
        else if title1.text!.count > 40 {
            let alert = UIAlertController(title: "Wait!", message: "Please limit your title to 40 characters", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
            
        else if loc.text!.count > 60 {
            let alert = UIAlertController(title: "Wait!", message: "Please limit your location to 60 characters", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        else {
            
            
            let myTimeStamp = post_date.timeIntervalSince1970 as! Double
            let stamp = myTimeStamp * 1000
            
            if link1 == nil {
                let post = ["eventid": key, "description": descript.text, "going": going, "host": user?.uid, "invited": invited, "location": loc.text ?? "Unknown", "public": publicEvent, "eventtime": stamp, "title": title1.text ?? "Unknown", "timeposted": final_stamp, "viewed": viewed, "editedtime": [".sv": "timestamp"], "category": cat.text] as [AnyHashable : Any]
                ref?.child("Events/" + key!).updateChildValues(post)
            }
            else {
                let post = ["eventid": key, "description": descript.text, "going": going, "host": user?.uid, "invited": invited, "location": loc.text ?? "Unknown", "public": publicEvent, "eventtime": stamp, "title": title1.text ?? "Unknown", "timeposted": final_stamp, "viewed": viewed, "editedtime": [".sv": "timestamp"], "category": cat.text, "link": link1] as [AnyHashable : Any]
                ref?.child("Events/" + key!).updateChildValues(post)
            }
            // Create a root reference
            let storageRef = storage.reference()
            
            // Create a reference to the file you want to upload
            let riversRef = storageRef.child("events/" + key! + ".png")
            
            let im = UIImage(data: imageData!)
            
            if let imageData2 = im?.jpeg(.lowest) {
                // Upload the file to the path "images/rivers.jpg"
                let uploadTask = riversRef.putData(imageData2, metadata: nil) { (metadata, error) in
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
            
            // update feed branch
            let upd2 = ["eventid": key, "timestamp": [".sv": "timestamp"], "userid": self.user?.uid] as [AnyHashable: Any]
            self.ref?.child("Feed/" + key! + "/" + user!.uid).updateChildValues(upd2)
            
            // update notification for invites
            for u in invited.keys {
                if self.going![u] == nil && self.viewed![u] == nil {
                    // add to individuals section in db
                    let upd3 = ["eventid": key!, "timestamp": [".sv": "timestamp"], "inviter": self.user!.uid, "viewed": false] as [AnyHashable: Any]
                    let path = "Users/" + u + "/Notifications/" + key!
                    self.ref?.child(path).updateChildValues(upd3)
                }
            }
            
            navigationController?.popViewController(animated: true)
        }
    }
    
    func receiveUpdatedInvitiation(invites: [String:String]){
        invited = invites
    }
    
    func receiveUpdatedLink(link : String) {
        self.link1 = link
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is AddFriendsTableViewController {
            let vc = segue.destination as? AddFriendsTableViewController
            vc?.users = users
            vc?.mainViewController = self
            vc?.addedFriends = invited
        }
        
        if segue.destination is AddLinkViewController {
            let vc = segue.destination as? AddLinkViewController
            vc?.mainViewController = self
            vc?.link = link1
        }
    }
    
    func getUsers() {
        var sen = 0
        self.ref?.child("Users/").observeSingleEvent(of: .value, with: {(snapshot) in
            if snapshot.childrenCount > 0 {
                for x in snapshot.children.allObjects as! [DataSnapshot] {
                    let infoObj = x.value as? [String: AnyObject]
                    let u = infoObj?["display"]
                    let email = infoObj?["user"]
                    let year = infoObj?["year"]
                    
                    if year != nil {
                        let y = year as! String
                        if y == "2023" {
                            sen = sen + 1
                        }
                    }
                    
                    print(sen)
                    if email == nil {
                        print(x)
                    }
                    if email != nil {
                    let e2 = email as! String
                    var alt = ""
                    if u != nil {
                        alt = u as! String
                    }
                    
                    let arr = e2.components(separatedBy: "@")
                    let e = arr[0]
                    
                    if self.user?.email != e2 {
                        let user = AddFriendModel(name1: alt, email1: e, id1: x.key)
                        if u != nil {
                            self.users.append(user)
                        }
                    }
                    self.users = self.users.sorted(by: {(a, b) -> Bool in
                        if let d1 = a.email {
                            if let d2 = b.email {
                                return d1 < d2
                            }
                            return false
                        }
                        return false
                    })
                    }
                }
            }
        })
    }
    
    @objc func dateAndTime(textField: UITextField) {
        self.view.endEditing(true)
        datepick.isHidden = false
        inviteButton.isHidden = true
        descript.isHidden = true
        photoButton.isHidden = true
        publicButton.isHidden = true
        privateButton.isHidden = true
        doneDate.isHidden = false
        addLink.isHidden = true
        categoryPicker.isHidden = true
    }
    
    @IBAction func doneDateTappe(_ sender: Any) {
        datepick.isHidden = true
        inviteButton.isHidden = false
        descript.isHidden = false
        photoButton.isHidden = false
        publicButton.isHidden = false
        privateButton.isHidden = false
        doneDate.isHidden = true
        categoryPicker.isHidden = true
        addLink.isHidden = false
        categoryPicker.isHidden = true
    }
    
    // set borders for text views
    func setTextViews() {
        let textViews = [descript]
        let borderColor : UIColor = UIColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1.0)
        for x in textViews {
            x!.layer.borderWidth = 0.5
            x!.layer.borderColor = borderColor.cgColor
            x!.layer.cornerRadius = 5.0
        }
    }
    
    //Calls this function when the tap is recognized.
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField.tag == 0 {
            view.endEditing(true)
        }
        if textField.tag == 1 {
            view.endEditing(true)
        }
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if descript.textColor == UIColor.lightGray {
            descript.text = nil
            descript.textColor = UIColor.black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if descript.text.isEmpty {
            descript.text = "Description"
            descript.textColor = UIColor.lightGray
        }
    }
    
    @IBAction func dateChange(_ sender: Any, forEvent event: UIEvent) {
        let formatter = DateFormatter()
        // initially set the format based on your datepicker date / server String
        formatter.dateFormat = "E, MMM d, h:mm a"
        
        post_date = datepick.date
        
        let myString = formatter.string(from: datepick.date)
        
        time.text = myString
    }
    
    @IBAction func publicTapped(_ sender: Any) {
        if !publicEvent {
            privateButton.layer.borderColor = UIColor(red:0.84, green:0.84, blue:0.84, alpha:1.0).cgColor
            privateButton.layer.backgroundColor = UIColor(red:0.84, green:0.84, blue:0.84, alpha:1.0).cgColor
            publicButton.layer.borderColor = UIColor(red:0.77, green:0.12, blue:0.23, alpha:1.0).cgColor
            publicButton.layer.backgroundColor = UIColor(red:0.77, green:0.12, blue:0.23, alpha:1.0).cgColor
            publicEvent = !publicEvent
        }
    }
    
    @IBAction func privateTapped(_ sender: Any) {
        if publicEvent {
            publicButton.layer.borderColor = UIColor(red:0.84, green:0.84, blue:0.84, alpha:1.0).cgColor
            publicButton.layer.backgroundColor = UIColor(red:0.84, green:0.84, blue:0.84, alpha:1.0).cgColor
            privateButton.layer.borderColor = UIColor(red:0.77, green:0.12, blue:0.23, alpha:1.0).cgColor
            privateButton.layer.backgroundColor = UIColor(red:0.77, green:0.12, blue:0.23, alpha:1.0).cgColor
            publicEvent = !publicEvent
        }
    }
    
    @IBAction func inviteFriendsTapped(_ sender: Any) {
        performSegue(withIdentifier: "toAddFriends", sender: nil)
    }
    
    @IBAction func AddPhotoTapped(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.allowsEditing = true
        picker.delegate = self
        present(picker, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.editedImage] as? UIImage else { return }
        
        dismiss(animated: true)
        
        
        if let imageData2 = image.jpeg(.lowest) {
            imageData = imageData2
        }
        
        photoButton.setTitle("Photo Added ✅", for: .normal)
        photoButton.setTitleColor(UIColor.green, for: .normal)
    }
    
    @IBAction func createTapped(_ sender: Any) {
        // leave no empty fields
        if title1.text == "" || loc.text == "" || time.text == "" || descript.text == "Description" || cat.text == "-" || cat.text == "" {
            let alert = UIAlertController(title: "Wait!", message: "Please fill out all the criteria for the event", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
            
        else if imageData == nil {
            let alert = UIAlertController(title: "Wait!", message: "Please add a photo", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
            
        else if descript.text.count > 160 {
            let alert = UIAlertController(title: "Wait!", message: "Please limit your description to 160 characters", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
            
        else if title1.text!.count > 40 {
            let alert = UIAlertController(title: "Wait!", message: "Please limit your title to 40 characters", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
            
        else if loc.text!.count > 60 {
            let alert = UIAlertController(title: "Wait!", message: "Please limit your location to 60 characters", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
            
        else {
            let userid = (user?.uid)!
            let description = self.descript.text! as String
            going = [userid: "nil"]
            host = userid
            viewed = [userid: "nil"]
            // invite raf to all events bc im special
            invited["Db4sWy7ivBMJiJk5EXrNL1gsPx32"] = "nil"
            let myTimeStamp = post_date.timeIntervalSince1970
            final_stamp = myTimeStamp * 1000
            
            key = ref?.childByAutoId().key
            
            if link1 == nil {
                 let post = ["eventid": key, "description": description, "going": going, "host": host ?? "Anonymous", "invited": invited, "location": loc.text ?? "Unknown", "public": publicEvent, "eventtime": final_stamp, "title": title1.text ?? "Unknown", "timeposted": [".sv": "timestamp"], "viewed": viewed, "category": cat.text] as [AnyHashable : Any]
                ref?.child("Events/" + key!).updateChildValues(post)
            }
            else {
                let post = ["eventid": key, "description": description, "going": going, "host": host ?? "Anonymous", "invited": invited, "location": loc.text ?? "Unknown", "public": publicEvent, "eventtime": final_stamp, "title": title1.text ?? "Unknown", "timeposted": [".sv": "timestamp"], "viewed": viewed, "category": cat.text, "link": link1] as [AnyHashable : Any]
                ref?.child("Events/" + key!).updateChildValues(post)
            }
            
            // Create a root reference
            let storageRef = storage.reference()
            
            // Create a reference to the file you want to upload
            let riversRef = storageRef.child("events/" + key! + ".png")
           
            let im = UIImage(data: imageData!)
            
            if let imageData2 = im?.jpeg(.lowest) {
                // Upload the file to the path "images/rivers.jpg"
                let uploadTask = riversRef.putData(imageData2, metadata: nil) { (metadata, error) in
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
            
            // update feed branch
            let upd2 = ["eventid": key, "timestamp": [".sv": "timestamp"], "userid": self.user?.uid] as [AnyHashable: Any]
            self.ref?.child("Feed/" + key! + "/" + user!.uid).updateChildValues(upd2)
            
            // update notification for invites
            for u in invited.keys {
                // add to individuals section in db
                let upd3 = ["eventid": key!, "timestamp": [".sv": "timestamp"], "inviter": self.user!.uid, "viewed": false] as [AnyHashable: Any]
                let path = "Users/" + u + "/Notifications/" + key!
                self.ref?.child(path).updateChildValues(upd3)
            }
            
            navigationController?.popViewController(animated: true)
        }
    }
}

