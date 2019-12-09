//
//  AdInfoViewController.swift
//  OurCampus
//
//  Created by Rafael Goldstein on 2/13/19.
//  Copyright © 2019 Rafael Goldstein. All rights reserved.
//

import UIKit
import WebKit

class AdInfoViewViewController: UIViewController, WKUIDelegate {
    
    var webView: WKWebView!
    
    override func loadView() {
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.uiDelegate = self
        view = webView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let myURL = URL(string:"http://ourcampus.us.com")
        let myRequest = URLRequest(url: myURL!)
        webView.load(myRequest)
    }

}
