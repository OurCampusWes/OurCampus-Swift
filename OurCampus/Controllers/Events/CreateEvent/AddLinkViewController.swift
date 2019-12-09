//
//  AddLinkViewController.swift
//  OurCampus
//
//  Created by Rafael Goldstein on 9/5/19.
//  Copyright © 2019 Rafael Goldstein. All rights reserved.
//

import UIKit

class AddLinkViewController: UIViewController {

    @IBOutlet weak var linkText: UITextField!
    
    var mainViewController : CreateEventViewController?
    
    var link : String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let attrs = [
            NSAttributedString.Key.foregroundColor: UIColor(red:0.77, green:0.12, blue:0.23, alpha:1.0),
            NSAttributedString.Key.font: UIFont(name: "OraqleScript", size: 50)!
        ]
        UINavigationBar.appearance().titleTextAttributes = attrs
        self.navigationItem.title = "Add Link"
        
        linkText.addTarget(self, action: #selector(textFieldDidChange), for: UIControl.Event.editingChanged)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if link != nil {
            linkText.text = link
        }
    }
    
    @objc func textFieldDidChange() {
        mainViewController?.receiveUpdatedLink(link: linkText.text!)
    }

}
