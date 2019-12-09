//
//  AddInfoViewController.swift
//  OurCampus
//
//  Created by Rafael Goldstein on 8/12/19.
//  Copyright © 2019 Rafael Goldstein. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import FirebaseMessaging

class AddInfoViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate,  UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {

    @IBOutlet weak var usernameEnter: UITextField!
    var username : String?
    var userid : String?
    var ref : DatabaseReference?
    var imageData : Data?
    
    @IBOutlet weak var classYear: UITextField!
    @IBOutlet weak var classPicker: UIPickerView!
    var pickerData: [String] = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        userid = Auth.auth().currentUser?.uid
        ref = Database.database().reference()

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneTapped))
        usernameEnter.addTarget(self, action: #selector(textFieldDidChange), for: UIControl.Event.editingChanged)
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
        
         classYear.addTarget(self, action: #selector(myTargetFunction), for: .touchDown)
        pickerData = ["2020", "2021", "2022", "2023"]
        
        self.classPicker.delegate = self
        self.classPicker.dataSource = self
        classPicker.isHidden = true
        classYear.tag = 0
        classYear.delegate = self
        self.tabBarController?.tabBar.isHidden = true
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        self.tabBarController?.tabBar.isHidden = false
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField.tag == 0 {
            view.endEditing(true)
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        classYear.text = pickerData[row]
    }
    
    @objc func myTargetFunction() {
        view.endEditing(true)
        classPicker.isHidden = false
    }
    
    //Calls this function when the tap is recognized.
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
        classPicker.isHidden = true
    }
    
    @objc func textFieldDidChange() {
        username = usernameEnter.text
    }
    
    @objc func doneTapped() {
        if imageData != nil && username != nil && classYear.text != "" {
            if username!.count > 15 && username!.count < 3 {
                // give user alert they need to fill out all info
                let alert = UIAlertController(title: "Wait", message: "Limit your display name between 3 and 15 characters", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
            else {
            // upload info to db
            let token = Messaging.messaging().fcmToken ?? ""
            let info = ["display": username, "incognito": false, "token": token, "year": classYear.text] as [AnyHashable:Any]
            
            ref?.child("Users/" + userid!).updateChildValues(info)
            
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
            
            self.performSegue(withIdentifier: "toHome", sender: nil)
        }
        
        else {
            // give user alert they need to fill out all info
            let alert = UIAlertController(title: "Wait", message: "Please add both a username and a profile picture", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func addImage(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.allowsEditing = true
        picker.delegate = self
        present(picker, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.editedImage] as? UIImage else { return }
        
        dismiss(animated: true)
        
        imageData = image.pngData()!
    }
    
}
