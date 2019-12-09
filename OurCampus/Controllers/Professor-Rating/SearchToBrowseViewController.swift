//
//  SearchToBrowseViewController.swift
//  OurCampus
//
//  Created by Rafael Goldstein on 12/28/18.
//  Copyright © 2018 Rafael Goldstein. All rights reserved.
//

import UIKit
import MessageUI
import Firebase
import FirebaseAuth

class SearchToBrowseViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, MFMailComposeViewControllerDelegate {
    
    @IBOutlet weak var acTblView: UITableView!
    @IBOutlet weak var search: UITextField!
    
    var autoCompletionPossibilities = [String]()
    
    var allProfs = [String]()
    var autoCompleteCharacterCount = 0
    
    var user: User?
    // declare database
    var ref : DatabaseReference?
    
    var profsDepsDict = [[String] : [String]]()
    var depsList = [String]()
    var profsAndDeps = [String]()
    var depsListWithProfs = [String: [[String]]]()
    var psSplitUpNames = [[String]]()
    var classes = [String]()
    
    @IBOutlet weak var goToDepsButton: UIButton!
    override func viewDidLoad() {
        
        super.viewDidLoad()
        let attrs = [
            NSAttributedString.Key.foregroundColor: UIColor(red:0.77, green:0.12, blue:0.23, alpha:1.0),
            NSAttributedString.Key.font: UIFont(name: "OraqleScript", size: 50)!
        ]
        UINavigationBar.appearance().titleTextAttributes = attrs
        self.navigationItem.title = "OurCampus"
        goToDepsButton.layer.cornerRadius = 5
        goToDepsButton.layer.borderWidth = 2.0
        goToDepsButton.layer.masksToBounds = true
        goToDepsButton.titleLabel?.font = UIFont(name: "Georgia", size: 14)
        goToDepsButton.setTitleColor(UIColor.black, for: .normal)
        goToDepsButton.layer.borderColor = UIColor(red:0.84, green:0.84, blue:0.84, alpha:1.0).cgColor
        goToDepsButton.layer.backgroundColor = UIColor(red:0.84, green:0.84, blue:0.84, alpha:1.0).cgColor
        
        search.delegate = self
        user = Auth.auth().currentUser
        // instantiating database
        ref = Database.database().reference()
        convertProfs()
        // combine deps with profs to search
        profsAndDeps = profsAndDeps + depsList
        
        acTblView.delegate = self;
        acTblView.dataSource = self;
        acTblView.isScrollEnabled = true
        acTblView.isHidden = true
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is BrowseProfsViewController {
            let vc = segue.destination as? BrowseProfsViewController
            vc?.text = search.text ?? ""
            vc?.psSplitUpNames = psSplitUpNames
            vc?.profsDepsDict = profsDepsDict
            vc?.depsList2 = depsList
            vc?.depsListWithProfs = depsListWithProfs
            vc?.classes = classes
        }
            
        else if segue.destination is BrowseDepsViewController {
            let vc = segue.destination as? BrowseDepsViewController
            vc?.text = search.text ?? ""
            vc?.psSplitUpNames = psSplitUpNames
            vc?.profsDepsDict = profsDepsDict
            vc?.depsList2 = depsList
            vc?.depsList = depsListWithProfs
            vc?.classes = classes
        }
    }
    
    func convertProfs()  {
        self.ref?.child("Ratings").observeSingleEvent(of: .value, with: {(snapshot) in
        if snapshot.childrenCount > 0 {
            for p in snapshot.children.allObjects as! [DataSnapshot] {
                self.allProfs.append(p.key)
                self.profsAndDeps.append(p.key)
                }
            }
        })
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if profsAndDeps.contains(search.text ?? "") {
            performSegue(withIdentifier: "browse", sender: nil)
            self.search.text = ""
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
        for p in profsAndDeps {
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
            performSegue(withIdentifier: "browse", sender: nil)
            self.search.text = ""
        }
        else if depsList.contains(search.text ?? "") {
            performSegue(withIdentifier: "toDep", sender: nil)
            self.search.text = ""
        }
        // else do nothing
    }
    
    @IBAction func helpClicked(_ sender: Any) {
        let alert = UIAlertController(title: "Need Help?", message: "If you're having an issue finding a professor, we might not have them in our database!", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil))
        alert.addTextField(configurationHandler: { textfield in
            textfield.placeholder = "Input professor name here..."
        })
        alert.addAction(UIAlertAction(title: "Submit", style: UIAlertAction.Style.default) { (action) in
            if self.user?.email == "support@ourcampus.us.com" {
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
    @IBAction func toolbar(_ sender: Any) {
        performSegue(withIdentifier: "toTools", sender: nil)
    }
    @IBAction func goToDeps(_ sender: Any) {
        performSegue(withIdentifier: "toWes", sender: nil)
    }
}
