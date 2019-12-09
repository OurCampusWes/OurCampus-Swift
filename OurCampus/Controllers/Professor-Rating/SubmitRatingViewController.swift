//
//  SubmitRatingViewController.swift
//  OurCampusXcode
//
//  Created by Rafael Goldstein on 11/27/18.
//  Copyright © 2018 Rafael Goldstein. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase

class SubmitRatingViewController: UIViewController, UITextViewDelegate {
    
    // text views, editable
    @IBOutlet weak var class1: UITextView!
    @IBOutlet weak var comments: UITextView!
    @IBOutlet weak var professor: UITextView!
    @IBOutlet weak var commentsLabel: UITextView!
    @IBOutlet weak var grade: UITextView!
    @IBOutlet weak var gradeLabel: UITextView!
    @IBOutlet weak var takeAgainLabel: UITextView!
    @IBOutlet weak var textbookLabel: UITextView!
    @IBOutlet weak var attendanceLabel: UITextView!
    @IBOutlet weak var rateSignLBL: UITextView!
    @IBOutlet weak var diffSignLBL: UITextView!
    @IBOutlet weak var submit: UIBarButtonItem!
    
    var prof = ""
    var className = ""
    
    var user : User?
    
    // declare database
    var ref : DatabaseReference?
    
    // sliders for difficulty and overall
    @IBOutlet weak var difficultySlider: UISlider!
    @IBOutlet weak var diffRate: UILabel!
    @IBOutlet weak var overallSlider: UISlider!
    @IBOutlet weak var overallRate: UILabel!
    @IBOutlet weak var lectureSlider: CustomUISlider!
    @IBOutlet weak var lectureRate: UILabel!
    @IBOutlet weak var returnsSliders: CustomUISlider!
    @IBOutlet weak var returnsRate: UILabel!
    @IBOutlet weak var discussionSlider: CustomUISlider!
    @IBOutlet weak var discussionRate: UILabel!
    
    // radio buttons for attendance, textbook, and would take again
    @IBOutlet weak var noAttendance: RadioButton!
    @IBOutlet weak var yesAttendance: RadioButton!
    @IBOutlet weak var noRadioButton: RadioButton!
    @IBOutlet weak var yesRadioButton: RadioButton!
    @IBOutlet weak var noTakeAgain: RadioButton!
    @IBOutlet weak var yesTakeAgain: RadioButton!
    
    var searchBar : UISearchBar!
    
    let network = NetworkManager.sharedInstance
    
    var users = [String]()
    
    @IBOutlet weak var chars: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let attrs = [
            NSAttributedString.Key.foregroundColor: UIColor(red:0.77, green:0.12, blue:0.23, alpha:1.0),
            NSAttributedString.Key.font: UIFont(name: "OraqleScript", size: 50)!
        ]
        UINavigationBar.appearance().titleTextAttributes = attrs
        self.navigationItem.title = "OurCampus"
        
        // set buttons
        setRadioButtons()
        
        difficultySlider.tag = 1
        overallSlider.tag = 0
        class1.tag = 5
        grade.tag = 6
        comments.tag = 7 
        
        
        user = Auth.auth().currentUser
        
        setTextViews()
        professor.tag = 2
        
        // instantiating database
        ref = Database.database().reference()
        
        class1.delegate = self
        comments.delegate = self
        professor.delegate = self
        grade.delegate = self
        
        let tapGesture2 = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard(_:)))
        view.addGestureRecognizer(tapGesture2)
        
        
        professor.text = prof
        professor.isEditable = false
        
        
        network.reachability.whenUnreachable = { reachability in
            self.showOfflinePage()
        }
        
        lectureRate.text = "Ineffective"
        returnsRate.text = "Ineffective"
        discussionRate.text = "Ineffective"
        
        chars.text = String(280 - comments.text.count)
        
        if className != "" {
            class1.text = className
            class1.isEditable = false
        }

    }
   
    
    private func showOfflinePage() -> Void {
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "NetworkUnavailable", sender: self)
        }
    }
    
    func setRadioButtons() {
        yesRadioButton?.isSelected = false
        noRadioButton?.isSelected = true
        yesRadioButton?.alternateButton = [noRadioButton!]
        noRadioButton?.alternateButton = [yesRadioButton!]
        yesRadioButton?.setText(text: "Yes")
        noRadioButton?.setText(text: "No")
        
        noAttendance?.isSelected = true
        yesAttendance?.isSelected = false
        noAttendance?.alternateButton = [yesAttendance!]
        yesAttendance?.alternateButton = [noAttendance!]
        yesAttendance?.setText(text: "Yes")
        noAttendance?.setText(text: "No")
        
        noTakeAgain?.isSelected = true
        yesTakeAgain?.isSelected = false
        noTakeAgain?.alternateButton = [yesTakeAgain!]
        yesTakeAgain?.alternateButton = [noTakeAgain!]
        yesTakeAgain?.setText(text: "Yes")
        noTakeAgain?.setText(text: "No")
    }
    
    // change val for label of overall rate slider
    @IBAction func overallSliderChanged(_ sender: UISlider) {
        let selectedValue = Int(sender.value)
        overallRate.text = String(selectedValue)
    }
    
    // change val for label of difficulty slider
    @IBAction func diffSliderChanged(_ sender: UISlider) {
        let selectedValue = Int(sender.value)
        diffRate.text = String(selectedValue)
    }
    
    @IBAction func lectureSliderChanged(_ sender: UISlider) {
        let selectedValue = Int(sender.value)
        if selectedValue == 1 {
            lectureRate.text = "Ineffective"
        }
        else if selectedValue == 2 {
            lectureRate.text = "Fair"
        }
        else if selectedValue == 3 {
            lectureRate.text = "Good"
        }
        else if selectedValue == 4 {
            lectureRate.text = "Very Good"
        }
        else {
            lectureRate.text = "Excellent"
        }
    }
    
    @IBAction func assignmentsSliderChanged(_ sender: UISlider) {
        let selectedValue = Int(sender.value)
        if selectedValue == 1 {
            returnsRate.text = "Ineffective"
        }
        else if selectedValue == 2 {
            returnsRate.text = "Fair"
        }
        else if selectedValue == 3 {
            returnsRate.text = "Good"
        }
        else if selectedValue == 4 {
            returnsRate.text = "Very Good"
        }
        else {
            returnsRate.text = "Excellent"
        }
    }
    
    @IBAction func discussionSliderChanged(_ sender: UISlider) {
        let selectedValue = Int(sender.value)
        if selectedValue == 1 {
            discussionRate.text = "Ineffective"
        }
        else if selectedValue == 2 {
            discussionRate.text = "Fair"
        }
        else if selectedValue == 3 {
            discussionRate.text = "Good"
        }
        else if selectedValue == 4 {
            discussionRate.text = "Very Good"
        }
        else {
            discussionRate.text = "Excellent"
        }
    }
    
    
    @objc func dismissKeyboard(_ sender: UITapGestureRecognizer) {
        view.endEditing(true)
    }
    
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.tag == 2 {
            view.endEditing(true)
        }
        
        else if textView.tag == 3 {
            view.endEditing(true)
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if(text == "\n") {
            textView.resignFirstResponder()
            return false
        }
        if textView.tag == 5 {
            let newText = (textView.text as NSString).replacingCharacters(in: range, with: text)
            let numberOfChars = newText.count
            return numberOfChars < 9
        }
        else if textView.tag == 6 {
            let newText = (textView.text as NSString).replacingCharacters(in: range, with: text)
            let numberOfChars = newText.count
            return numberOfChars < 3
        }
        else if textView.tag == 7 {
            let newText = (textView.text as NSString).replacingCharacters(in: range, with: text)
            let numberOfChars = newText.count
            chars.text = String(280 - (numberOfChars))
            if chars.text == "-1" {
                chars.text = "0"
            }
            
            return numberOfChars < 281
        }
       
        return true
    }
        
    func textViewClear(textView: UITextView) {
        textView.text = ""
    }
    
    // set borders for text views
    func setTextViews() {
        let textViews = [grade, professor, comments, class1]
        let borderColor : UIColor = UIColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1.0)
        for x in textViews {
            x!.layer.borderWidth = 0.5
            x!.layer.borderColor = borderColor.cgColor
            x!.layer.cornerRadius = 5.0
        }
    }
    
    // clear text view inputs
    func clearTexts() {
        let textViews = [grade, comments, class1]
        for x in textViews {
            textViewClear(textView: x!)
        }
    }
    
    // check if string can be converted to int
    func isStringNotInt(string: String) -> Bool {
        return Int(string) == nil
    }
    
    @IBAction func addRating(_ sender: Any) {
        let profName = self.professor.text.replacingOccurrences(of: ".", with: "")
        // if theres no rating, don't go through any checking
        ref = Database.database().reference().child("Ratings/" + profName + "/")
        
        var users = [String]()
        ref?.observeSingleEvent(of: .value, with: {(snapshot2) in
            if snapshot2.childrenCount > 0 {
                for x in snapshot2.children.allObjects as! [DataSnapshot] {
                    let infoObj = x.value as? [String: AnyObject]
                    let u = infoObj?["user"]
                    users.append(u as! String)
                }
                if users.contains((self.user?.email)!) {
                    // do nothing bc user has already submitted a review
                    let alert = UIAlertController(title: "Unable to Submit Rating", message: "You only get one rating per professor", preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
                else {
                    if self.class1.text == "" {
                        let alert = UIAlertController(title: "Unable to Submit Rating", message: "Please add a class", preferredStyle: UIAlertController.Style.alert)
                        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    }
                    else if self.comments.text == "" {
                        let alert = UIAlertController(title: "Unable to Submit Rating", message: "Please add a comment", preferredStyle: UIAlertController.Style.alert)
                        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    }
                    else if self.professor.text == "" {
                        let alert = UIAlertController(title: "Unable to Submit Rating", message: "Please add a professor", preferredStyle: UIAlertController.Style.alert)
                        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    }
                    else {
                        var access: String
                        var recommend: String
                        var feedback: String
                        
                        var lecture: String
                        var returns: String
                        var discussion: String
                        if self.noAttendance.isSelected {
                            access = "Not Accessible"
                        }
                        else {
                            access = "Accessible"
                        }
                        
                        if self.noRadioButton.isSelected {
                            feedback = "No"
                        }
                        else {
                            feedback = "Yes"
                        }
                        
                        if self.noTakeAgain.isSelected {
                            recommend = "No"
                        }
                        else {
                            recommend = "Yes"
                        }
                        
                        if self.lectureRate.text == "Ineffective" {
                            lecture = "1"
                        }
                        else if self.lectureRate.text == "Fair" {
                            lecture = "2"
                        }
                        else if self.lectureRate.text == "Good" {
                            lecture = "3"
                        }
                        else if self.lectureRate.text == "Very Good" {
                            lecture = "4"
                        }
                        else {
                            lecture = "5"
                        }
                        
                        if self.returnsRate.text == "Ineffective" {
                            returns = "1"
                        }
                        else if self.returnsRate.text == "Fair" {
                            returns = "2"
                        }
                        else if self.returnsRate.text == "Good" {
                            returns = "3"
                        }
                        else if self.returnsRate.text == "Very Good" {
                            returns = "4"
                        }
                        else {
                            returns = "5"
                        }
                        
                        if self.discussionRate.text == "Ineffective" {
                            discussion = "1"
                        }
                        else if self.discussionRate.text == "Fair" {
                            discussion = "2"
                        }
                        else if self.discussionRate.text == "Good" {
                            discussion = "3"
                        }
                        else if self.discussionRate.text == "Very Good" {
                            discussion = "4"
                        }
                        else {
                            discussion = "5"
                        }
                        
                        let alert = UIAlertController(title: "Are you sure?", message: "You cannot edit ratings. Please make sure your submission is fully representative of your opinion.", preferredStyle: UIAlertController.Style.alert)
                        let actSubmit = UIAlertAction(title: "Submit", style: UIAlertAction.Style.default) { (action) in
                            let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short)
                            let classUpdate = ["class": self.class1.text as String,
                                               "rate": self.overallRate.text! as String,
                                               "difficulty": self.diffRate.text! as String,
                                               "comments": self.comments.text! as String,
                                               "accessible": access,
                                               "feedback": feedback,
                                               "recommend": recommend,
                                               "lecture": lecture,
                                               "returns": returns,
                                               "discussion": discussion,
                                               "grade": self.grade.text! as String,
                                               "user": self.user?.email,
                                               "timestamp": timestamp]
                            let key = self.ref?.childByAutoId().key
                            
                            self.ref?.child(key!).updateChildValues(classUpdate as [AnyHashable : Any])
                            self.clearTexts()
                            let progressHUD = ProgressHUD(text: "Submitting")
                            self.view.addSubview(progressHUD)
                            self.ref?.removeAllObservers()
                            self.navigationController?.popViewController(animated: true)
                        }
                        let actReturn = UIAlertAction(title: "Return", style: UIAlertAction.Style.destructive, handler: nil)
                        alert.addAction(actReturn)
                        alert.addAction(actSubmit)
                        self.present(alert, animated: true, completion: nil)
                    }
                }
            }
            else {
                if self.class1.text == "" {
                    let alert = UIAlertController(title: "Unable to Submit Rating", message: "Please add a class", preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
                else if self.comments.text == "" {
                    let alert = UIAlertController(title: "Unable to Submit Rating", message: "Please add a comment", preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
                else if self.professor.text == "" {
                    let alert = UIAlertController(title: "Unable to Submit Rating", message: "Please add a professor", preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
                else {
                    var access: String
                    var recommend: String
                    var feedback: String
                    
                    var lecture: String
                    var returns: String
                    var discussion: String
                
                    if self.noAttendance.isSelected {
                        access = "No"
                    }
                    else {
                        access = "Yes"
                    }
                    
                    if self.noRadioButton.isSelected {
                        feedback = "No"
                    }
                    else {
                        feedback = "Yes"
                    }
                    
                    if self.noTakeAgain.isSelected {
                        recommend = "No"
                    }
                    else {
                        recommend = "Yes"
                    }
                    
                    if self.lectureRate.text == "Ineffective" {
                        lecture = "1"
                    }
                    else if self.lectureRate.text == "Fair" {
                        lecture = "2"
                    }
                    else if self.lectureRate.text == "Good" {
                        lecture = "3"
                    }
                    else if self.lectureRate.text == "Very Good" {
                        lecture = "4"
                    }
                    else {
                        lecture = "5"
                    }
                    
                    if self.returnsRate.text == "Ineffective" {
                        returns = "1"
                    }
                    else if self.returnsRate.text == "Fair" {
                        returns = "2"
                    }
                    else if self.returnsRate.text == "Good" {
                        returns = "3"
                    }
                    else if self.returnsRate.text == "Very Good" {
                        returns = "4"
                    }
                    else {
                        returns = "5"
                    }
                    
                    if self.discussionRate.text == "Ineffective" {
                        discussion = "1"
                    }
                    else if self.discussionRate.text == "Fair" {
                        discussion = "2"
                    }
                    else if self.discussionRate.text == "Good" {
                        discussion = "3"
                    }
                    else if self.discussionRate.text == "Very Good" {
                        discussion = "4"
                    }
                    else {
                        discussion = "5"
                    }
                    
                    let alert = UIAlertController(title: "Are you sure?", message: "You cannot edit ratings. Please make sure your submission is fully representative of your opinion.", preferredStyle: UIAlertController.Style.alert)
                    let actSubmit = UIAlertAction(title: "Submit", style: UIAlertAction.Style.default) { (action) in
                        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short)
                        let classUpdate = ["class": self.class1.text as String,
                                           "rate": self.overallRate.text! as String,
                                           "difficulty": self.diffRate.text! as String,
                                           "comments": self.comments.text! as String,
                                           "accessible": access,
                                           "feedback": feedback,
                                           "recommend": recommend,
                                           "lecture": lecture,
                                           "returns": returns,
                                           "discussion": discussion,
                                           "grade": self.grade.text! as String,
                                           "user": self.user?.email,
                                           "timestamp": timestamp]
                        let key = self.ref?.childByAutoId().key
                        
                        self.ref?.child(key!).updateChildValues(classUpdate as [AnyHashable : Any])
                        
                        self.clearTexts()
                        let progressHUD = ProgressHUD(text: "Submitting")
                        self.view.addSubview(progressHUD)
                        self.ref?.removeAllObservers()
                        self.navigationController?.popViewController(animated: true)
                    }
                    let actReturn = UIAlertAction(title: "Return", style: UIAlertAction.Style.destructive, handler: nil)
                    alert.addAction(actReturn)
                    alert.addAction(actSubmit)
                    self.present(alert, animated: true, completion: nil)
                }
            }
        })
    }
}


