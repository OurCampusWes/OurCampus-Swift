//
//  SearchProfsViewController.swift
//  OurCampus
//
//  Created by Rafael Goldstein on 12/26/18.
//  Copyright © 2018 Rafael Goldstein. All rights reserved.
//

import UIKit
import MessageUI
import Firebase
import FirebaseAuth

class SearchProfsViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource {
    
    var profsSplitUpNames = [[String]]()
    @IBOutlet weak var search: UITextField!
    @IBOutlet weak var acTblView: UITableView!
    
    var autoCompletionPossibilities = [String]()
    var allProfs = [String]()
    var autoCompleteCharacterCount = 0
    var timer = Timer()
    
    var user: User!
    var ref : DatabaseReference?
    
    var profsDepsDict = [[String] : [String]]()
    var depsList = [String]()
    var profsAndDeps = [String]()
    var depsListWithProfs = [String: [[String]]]()
    var classes = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let attrs = [
            NSAttributedString.Key.foregroundColor: UIColor(red:0.77, green:0.12, blue:0.23, alpha:1.0),
            NSAttributedString.Key.font: UIFont(name: "OraqleScript", size: 50)!
        ]
        UINavigationBar.appearance().titleTextAttributes = attrs
        self.navigationItem.title = "OurCampus"
        
        search.delegate = self
        
        allProfs = convertProfs(ps: profsSplitUpNames)
        
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
            vc?.prof = search.text ?? ""
        }
        
        else if segue.destination is EvalClassViewController {
            let vc = segue.destination as? EvalClassViewController
            vc?.profsSplitUpNames = profsSplitUpNames
            vc?.profsDepsDict = profsDepsDict
            vc?.depsList = depsList
            vc?.depsListWithProfs = depsListWithProfs
            vc?.classes = classes
            vc?.prof = search.text ?? ""
        }
    }
    
    func convertProfs(ps: [[String]]) -> [String] {
        var newLst = [String]()
        for p in ps {
            newLst.append(p[0] + ", " + p[1])
        }
        return newLst
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if allProfs.contains(search.text ?? "") {
            performSegue(withIdentifier: "toSubmit", sender: nil)
        }
        else {
            let alert = UIAlertController(title: "Unable to Begin Review", message: "Please input a valid professor name", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        return true
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
        for p in allProfs {
            let fullNameArr = p.components(separatedBy: " ")
            for w in fullNameArr {
                if w.hasPrefix(substring) {
                    if !autoCompletionPossibilities.contains(p) {
                        autoCompletionPossibilities.append(p)
                    }
                }
            }
        }
        acTblView.reloadData()
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
        if allProfs.contains(search.text ?? "") {
            performSegue(withIdentifier: "toClass", sender: nil)
            self.search.text = ""
        }
    }
    
    @IBAction func helpClicked(_ sender: Any) {
        let alert = UIAlertController(title: "Need Help?", message: "If you're having an issue finding a professor, we might not have them in our database!", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil))
        alert.addTextField(configurationHandler: { textfield in
            textfield.placeholder = "Input professor name here..."
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
