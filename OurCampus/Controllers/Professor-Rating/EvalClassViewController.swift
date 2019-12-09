//
//  EvalClassViewController.swift
//  OurCampus
//
//  Created by Rafael Goldstein on 2/12/19.
//  Copyright © 2019 Rafael Goldstein. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth

class EvalClassViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    
    var profsDepsDict = [[String] : [String]]()
    var depsList = [String]()
    var profsAndDeps = [String]()
    var depsListWithProfs = [String: [[String]]]()
    var profsSplitUpNames = [[String]]()
    var classes = [String]()
    
    var prof = ""
    
    @IBOutlet weak var search: UITextField!
    @IBOutlet weak var acTblView: UITableView!
    
    var autoCompletionPossibilities = [String]()
    var allProfs = [String]()
    var autoCompleteCharacterCount = 0
    var timer = Timer()
    
    var user: User!
    var ref : DatabaseReference?
    
    var pickedClass = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        search.delegate = self
        
        acTblView.delegate = self;
        acTblView.dataSource = self;
        acTblView.isScrollEnabled = true
        acTblView.isHidden = true
        user = Auth.auth().currentUser
        ref = Database.database().reference()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is SubmitRatingViewController {
            let vc = segue.destination as? SubmitRatingViewController
            vc?.prof = prof
            vc?.className = self.search.text ?? ""
        }
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
        self.search.text = autoCompletionPossibilities[indexPath.row]
        acTblView.isHidden = true
        if classes.contains(search.text ?? "") {
            performSegue(withIdentifier: "toSubmit", sender: nil)
            self.search.text = ""
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        acTblView.isHidden = false
        var substring = search.text
        substring = formatSubstring(subString: substring ?? "")
        searchAutocompleteEntriesWithSubstring(substring: substring!)
        return true
    }
    
    func formatSubstring(subString: String) -> String {
        let formatted = String(subString.dropLast(autoCompleteCharacterCount)).lowercased().capitalized //5
        return formatted
    }

    func searchAutocompleteEntriesWithSubstring(substring: String) {
        autoCompletionPossibilities.removeAll()
        for p in classes {
            if p.hasPrefix(substring) || p.hasPrefix(substring.uppercased()) {
                    if !autoCompletionPossibilities.contains(p) {
                        autoCompletionPossibilities.append(p)
                    }
            }
        }
        acTblView.reloadData()
    }
    
    @IBAction func helpClicked(_ sender: Any) {
        let alert = UIAlertController(title: "Need Help?", message: "If you're having an issue finding a class, we might not have them in our database!", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil))
        alert.addTextField(configurationHandler: { textfield in
            textfield.placeholder = "Input class name here..."
        })
        alert.addAction(UIAlertAction(title: "Submit", style: UIAlertAction.Style.default) { (action) in
            if self.user.email == "support@ourcampus.us.com" {
                let alert = UIAlertController(title: "Unable to Submit", message: "You must be signed into a wesleyan email to submit a suggestion", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
            else {
                if let name = alert.textFields?.first?.text {
                    let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short)
                    let missingUpdate = ["time": timestamp,
                                         "name": name,
                                         "user": self.user?.email]
                    let key = self.ref?.child("Missing").childByAutoId().key
                    
                    self.ref?.child("Missing/" + key!).updateChildValues(missingUpdate as [AnyHashable : Any])
                }
            }
        })
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func toolBar(_ sender: Any) {
        performSegue(withIdentifier: "toTools", sender: nil)
    }
}
