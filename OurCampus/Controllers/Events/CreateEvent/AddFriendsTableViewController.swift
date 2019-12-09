//
//  AddFriendsTableViewController.swift
//  OurCampus
//
//  Created by Rafael Goldstein on 7/15/19.
//  Copyright © 2019 Rafael Goldstein. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase

class AddFriendsTableViewController: UITableViewController {
    
    var addedFriends = [String:String]()
    var user : User?
    
    // declare database
    var ref : DatabaseReference?
    
    var users = [AddFriendModel]()
    
    let searchController = UISearchController(searchResultsController: nil)
    
    var filteredNames = [AddFriendModel]()
    
    var mainViewController : CreateEventViewController?

    
    override func viewDidLoad() {
        super.viewDidLoad()

        user = Auth.auth().currentUser
        ref = Database.database().reference()
        
        // Setup the Search Controller
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search by Wesleyan username"
        navigationItem.searchController = searchController
        definesPresentationContext = true
        navigationItem.hidesSearchBarWhenScrolling = false
        
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "friend", for: indexPath) as! AddFriendsTableViewCell
        
        var list : [AddFriendModel]
        if isFiltering() {
            list = filteredNames
        } else {
            list = users
        }
        
        if list[indexPath.row].name == "" {
            cell.name.text = list[indexPath.row].email
        }
        else {
            cell.name.text = list[indexPath.row].name! + " (" + list[indexPath.row].email! + ")"
            
        }
        
        cell.addButton.tag = indexPath.row
        cell.addButton.addTarget(self, action: #selector(self.addTapped), for: .touchUpInside)
        cell.selectionStyle = .none
        
        if addedFriends.keys.contains(list[indexPath.row].id!) {
            cell.addButton.setTitle("Remove", for: .normal)
        }
        else {
            cell.addButton.setTitle("Add", for: .normal)
        }
        
        
        return cell
    }
    
    @objc func addTapped(sender: UIButton) {
        let idx = sender.tag
        
        if sender.titleLabel?.text == "Remove" {
            if isFiltering() {
                addedFriends.removeValue(forKey: filteredNames[idx].id!)
                
            } else {
                addedFriends.removeValue(forKey: users[idx].id!)
            }
            
            sender.setTitle("Add", for: .normal)
        }
        
        else {
            if isFiltering() {
                addedFriends[filteredNames[idx].id!] = "nil"
            } else {
                addedFriends[users[idx].id!] = "nil"
            }
            sender.setTitle("Remove", for: .normal)
        }
        
        self.mainViewController!.receiveUpdatedInvitiation(invites: addedFriends)
    }
    
    func searchBarIsEmpty() -> Bool {
        // Returns true if the text is empty or nil
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    func filterContentForSearchText(_ searchText: String) {
        
        // check both names and emails
        filteredNames = users.filter( {(friend : AddFriendModel) -> Bool in
            return friend.email!.lowercased().contains(searchText.lowercased())
        })
        
        tableView.reloadData()
    }
    
    func isFiltering() -> Bool {
        return searchController.isActive && !searchBarIsEmpty()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFiltering() {
            return filteredNames.count
        }
        
        return users.count
    }

}
extension AddFriendsTableViewController: UISearchResultsUpdating {
    // MARK: - UISearchResultsUpdating Delegate
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }
}
